package com.rubyeventmachine;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.SocketChannel;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;

import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLEngine;
import javax.net.ssl.SSLEngineResult;
import javax.net.ssl.SSLEngineResult.HandshakeStatus;
import javax.net.ssl.SSLEngineResult.Status;
import javax.net.ssl.SSLPeerUnverifiedException;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class SslBox {

	private final SSLContext sslContext;
	private final SSLEngine sslEngine;
	
    private final ByteBuffer netInBuffer;
    private final ByteBuffer netOutBuffer;
    private final ByteBuffer anotherBuffer;

    public static ByteBuffer emptyBuf = ByteBuffer.allocate(0);
    private final SocketChannel channel;

	private boolean handshakeComplete;
    protected HandshakeStatus handshakeStatus; //gets set by handshake
    
	public SslBox(boolean isServer, SocketChannel channel, KeyStore keyStore, X509TrustManager tm, boolean verifyPeer, String host, int port) {
		try {
			sslContext = SSLContext.getInstance("TLS");
			KeyManager[] keyManagers = null;

			if (keyStore != null) {
				KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
				kmf.init(keyStore, null);
				keyManagers = kmf.getKeyManagers();
			}

			sslContext.init(keyManagers, new TrustManager[] { tm }, null);
			sslEngine = sslContext.createSSLEngine(host, port);
			sslEngine.setUseClientMode(!isServer);
			sslEngine.setNeedClientAuth(verifyPeer);
			
			this.channel = channel;
			
			int netBufSize = sslEngine.getSession().getPacketBufferSize();
			netInBuffer = ByteBuffer.allocate(netBufSize);
			netOutBuffer = ByteBuffer.allocate(netBufSize);
			anotherBuffer = ByteBuffer.allocate(netBufSize);
			reset();
		} catch (NoSuchAlgorithmException e) {
			throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
		} catch (UnrecoverableKeyException e) {
			throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
		} catch (KeyStoreException e) {
			throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
		} catch (KeyManagementException e) {
			throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
		} catch (IOException e) {
			throw new RuntimeException("unable to start TLS: " + e.getMessage(), e);
		}
	}

    public void reset() throws IOException {
        netOutBuffer.position(0);
        netOutBuffer.limit(0);
        netInBuffer.position(0);
        netInBuffer.limit(0);
        handshakeComplete = false;
        //initiate handshake
        sslEngine.beginHandshake();
        handshakeStatus = sslEngine.getHandshakeStatus();
    }

	public boolean handshake(SelectionKey channelKey) {
		try {
			int newOps = do_handshake(channelKey.isReadable(), channelKey.isWritable());
			channelKey.interestOps(newOps);
		} catch (IOException e) {
			return false;
		}
		return true;
	}

	public boolean handshakeNeeded() {
		return !handshakeComplete;
	}
	
	private int do_handshake(boolean read, boolean write) throws IOException {
        if (!flush(netOutBuffer)) return SelectionKey.OP_WRITE; //we still have data to write

        SSLEngineResult handshake = null;

        while (!handshakeComplete) {
            switch ( handshakeStatus ) {
                case FINISHED: {
                    //we are complete if we have delivered the last package
                    handshakeComplete = !netOutBuffer.hasRemaining();
                    //return 0 if we are complete, otherwise we still have data to write
                    return handshakeComplete?0:SelectionKey.OP_WRITE;
                }
                case NEED_WRAP: {
                    //perform the wrap function
                    handshake = handshakeWrap(write);
                    if ( handshake.getStatus() == Status.OK ){
                        if (handshakeStatus == HandshakeStatus.NEED_TASK)
                            handshakeStatus = tasks();
                    } else {
                        //wrap should always work with our buffers
                        throw new IOException("Unexpected status:" + handshake.getStatus() + " during handshake WRAP.");
                    }
                    if ( handshakeStatus != HandshakeStatus.NEED_UNWRAP || (!flush(netOutBuffer)) ) {
                        //should actually return OP_READ if we have NEED_UNWRAP
                        return SelectionKey.OP_WRITE;
                    }
                    //fall down to NEED_UNWRAP on the same call, will result in a
                    //BUFFER_UNDERFLOW if it needs data
                }
                //$FALL-THROUGH$
                case NEED_UNWRAP: {
                    //perform the unwrap function
                    handshake = handshakeUnwrap(read);
                    if ( handshake.getStatus() == Status.OK ) {
                        if (handshakeStatus == HandshakeStatus.NEED_TASK)
                            handshakeStatus = tasks();
                    } else if ( handshake.getStatus() == Status.BUFFER_UNDERFLOW ){
                        //read more data, reregister for OP_READ
                        return SelectionKey.OP_READ;
                    } else {
                        throw new IOException("Invalid handshake status:"+handshakeStatus+" during handshake UNWRAP.");
                    }//switch
                    break;
                }
                case NEED_TASK: {
                    handshakeStatus = tasks();
                    break;
                }
                default: throw new IllegalStateException("Invalid handshake status:"+handshakeStatus);
            }//switch
        }//while
        //return 0 if we are complete, otherwise reregister for any activity that
        //would cause this method to be called again.
        return handshakeComplete?0:(SelectionKey.OP_WRITE|SelectionKey.OP_READ);
	}
	
	
    /**
     * Performs the WRAP function
     * @param doWrite boolean
     * @return SSLEngineResult
     * @throws IOException
     */
    private SSLEngineResult handshakeWrap(boolean doWrite) throws IOException {
        //this should never be called with a network buffer that contains data
        //so we can clear it here.
        netOutBuffer.clear();
        //perform the wrap
        SSLEngineResult result = sslEngine.wrap(emptyBuf, netOutBuffer);
        //prepare the results to be written
        netOutBuffer.flip();
        //set the status
        handshakeStatus = result.getHandshakeStatus();
        //optimization, if we do have a writable channel, write it now
        if ( doWrite ) flush(netOutBuffer);
        return result;
    }

    /**
     * Perform handshake unwrap
     * @param doread boolean
     * @return SSLEngineResult
     * @throws IOException
     */
    private SSLEngineResult handshakeUnwrap(boolean doread) throws IOException {

        if (netInBuffer.position() == netInBuffer.limit()) {
            //clear the buffer if we have emptied it out on data
            netInBuffer.clear();
        }
        if ( doread )  {
            //if we have data to read, read it
            int read = channel.read(netInBuffer);
            if (read == -1) throw new IOException("EOF encountered during handshake.");
        }
        SSLEngineResult result;
        boolean cont = false;
        //loop while we can perform pure SSLEngine data
        do {
            //prepare the buffer with the incoming data
            netInBuffer.flip();
            //call unwrap
            result = sslEngine.unwrap(netInBuffer, anotherBuffer);
            //compact the buffer, this is an optional method, wonder what would happen if we didn't
            netInBuffer.compact();
            //read in the status
            handshakeStatus = result.getHandshakeStatus();
            if ( result.getStatus() == SSLEngineResult.Status.OK &&
                 result.getHandshakeStatus() == HandshakeStatus.NEED_TASK ) {
                //execute tasks if we need to
                handshakeStatus = tasks();
            }
            //perform another unwrap?
            cont = result.getStatus() == SSLEngineResult.Status.OK &&
                   handshakeStatus == HandshakeStatus.NEED_UNWRAP;
        }while ( cont );
        return result;
    }

    /**
     * Executes all the tasks needed on the same thread.
     * @return HandshakeStatus
     */
    private SSLEngineResult.HandshakeStatus tasks() {
        Runnable r = null;
        while ( (r = sslEngine.getDelegatedTask()) != null) {
            r.run();
        }
        return sslEngine.getHandshakeStatus();
    }
    
    protected boolean flush(ByteBuffer buf) throws IOException {
        int remaining = buf.remaining();
        if ( remaining > 0 ) {
            int written = channel.write(buf);
            return written >= remaining;
        }else {
            return true;
        }
    }

	public javax.security.cert.X509Certificate getPeerCert() throws SSLPeerUnverifiedException {
		return sslEngine.getSession().getPeerCertificateChain()[0];
	}
	
    public int write(ByteBuffer src) throws IOException {
        if (!flush(netOutBuffer)) return 0;

        netOutBuffer.clear();

        SSLEngineResult result = sslEngine.wrap(src, netOutBuffer);
        int written = result.bytesConsumed();
        netOutBuffer.flip();

        if (result.getStatus() == Status.OK) {
        	if (result.getHandshakeStatus() == HandshakeStatus.NEED_TASK)
        		tasks();
        } else {
            throw new IOException("Unable to wrap data, invalid engine state: " +result.getStatus());
        }

        //force a flush
        flush(netOutBuffer);

        return written;
    }
    
    public int read(ByteBuffer dst) throws IOException {
        //did we finish our handshake?
        if (!handshakeComplete) throw new IllegalStateException("Handshake incomplete, you must complete handshake before reading data.");

        //read from the network
        int netread = channel.read(netInBuffer);
        //did we reach EOF? if so send EOF up one layer.
        if (netread == -1) return -1;

        //the data read
        int read = 0;
        //the SSL engine result
        SSLEngineResult unwrap;
        do {
            //prepare the buffer
            netInBuffer.flip();
            //unwrap the data
            unwrap = sslEngine.unwrap(netInBuffer, dst);
            //compact the buffer
            netInBuffer.compact();

            if ( unwrap.getStatus()==Status.OK || unwrap.getStatus()==Status.BUFFER_UNDERFLOW ) {
                //we did receive some data, add it to our total
                read += unwrap.bytesProduced();
                //perform any tasks if needed
                if (unwrap.getHandshakeStatus() == HandshakeStatus.NEED_TASK) tasks();
                //if we need more network data, then bail out for now.
                if ( unwrap.getStatus() == Status.BUFFER_UNDERFLOW ) break;
            }else if ( unwrap.getStatus()==Status.BUFFER_OVERFLOW && read>0 ) {
                //buffer overflow can happen, if we have read data, then
                //empty out the dst buffer before we do another read
                break;
            }else {
                //here we should trap BUFFER_OVERFLOW and call expand on the buffer
                //for now, throw an exception, as we initialized the buffers
                //in the constructor
                throw new IOException("Unable to unwrap data, invalid status: " + unwrap.getStatus());
            }
        } while ( (netInBuffer.position() != 0)); //continue to unwrapping as long as the input buffer has stuff
        return (read);
    }

}