require "rake/testtask"
require "rake/clean"
require "yaml"
require "openssl"

Rake::TestTask.new(:test) do |t|
  t.pattern = 'tests/**/test_*.rb'
  t.warning = true
end

directory "tests/fixtures"

namespace "test" do

  namespace "fixtures" do

    CLEAN_FIXTURES = ::Rake::FileList[
      "tests/fixtures/*.csr"
    ]
    CLOBBER_FIXTURES = ::Rake::FileList[
      "tests/fixtures/*.aes-key",
      "tests/fixtures/*.crt",
      "tests/fixtures/*.key",
      "tests/fixtures/*.pass",
      "tests/fixtures/*.pem",
      "tests/fixtures/*.pub",
    ]

    desc "Remove temporary test fixture files"
    task :clean do
      Rake::Cleaner.cleanup_files(CLEAN_FIXTURES)
    end

    desc "Remove all generated test fixture files"
    task clobber: %i[clean] do
      Rake::Cleaner.cleanup_files(CLOBBER_FIXTURES)
    end

    desc "Remove certs which may have expired"
    task :expire do
      any_expired = CLOBBER_FIXTURES.ext('crt')
        .map {|f| load_cert(f) }
        .any? {|c| c.not_after < Time.now + 60 }
      Rake::Task["test:fixtures:clobber"].invoke if any_expired
    end

    desc "Generate all certificates"
    task certs: :expire

    def write_pem(obj, file, passphrase: nil)
      cipher = OpenSSL::Cipher.new 'AES-128-CBC'
      open(file, "w") do |io|
        io << (
          passphrase ? obj.to_pem(cipher, passphrase) : obj.to_pem
        )
      end
    end

    def x509_subject(cfg)
      subject = cfg.fetch("subject")
      subject.respond_to?(:to_a) ?
        OpenSSL::X509::Name.new(subject.to_a) :
        OpenSSL::X509::Name.parse(subject.to_str)
    end

    def x509_not_after(cfg)
      Time.now + (cfg.fetch("ttl_hours", 24) * 60 * 60)
    end

    def x509_make_csr(cfg, key)
      csr = OpenSSL::X509::Request.new
      csr.subject = x509_subject(cfg)
      csr.version = cfg.fetch("version", 2) # 2 == v3
      csr.public_key = key.public_key
      csr.sign key, OpenSSL::Digest::SHA256.new
      csr
    end

    def x509_random_serial
      rand(1..(2**159-1))
    end

    def load_cfg(f)
      YAML.load(File.read(f))
    end

    def load_cert(f)
      open(f) {|io| OpenSSL::X509::Certificate.new(io.read) }
    end

    def load_key(f, passfile=nil)
      passphrase = File.read(passfile) if passfile
      open(f) {|io| OpenSSL::PKey.read(io, passphrase) }
    end

    def get_ca_crt_and_key(ca)
      ca_crtfile = "tests/fixtures/#{ca}.crt"
      ca_keyfile = "tests/fixtures/#{ca}.key"
      ca_crt = open(ca_crtfile) {|io| OpenSSL::X509::Certificate.new(io.read) }
      ca_key = open(ca_keyfile) {|io| OpenSSL::PKey.read(io) }
      [ca_crt, ca_key]
    end

    # Following the example from the stdlib openssl gem
    def x509_make_ca_crt(cfg, key)
      crt = OpenSSL::X509::Certificate.new
      crt.version    = cfg.fetch("version", 3)
      crt.serial     = x509_random_serial
      crt.not_before = Time.now
      crt.not_after  = x509_not_after(cfg)
      crt.public_key = key.public_key
      crt.subject    = x509_subject(cfg)
      crt.issuer     = crt.subject # CA cert is self-signed!

      xf = OpenSSL::X509::ExtensionFactory.new
      xf.subject_certificate = crt
      xf.issuer_certificate = crt
      crt.add_extension xf.create_extension("subjectKeyIdentifier", "hash")
      crt.add_extension xf.create_extension("basicConstraints", "CA:TRUE", true)
      crt.add_extension xf.create_extension("keyUsage", "cRLSign,keyCertSign", true)

      crt.sign key, OpenSSL::Digest::SHA256.new
      crt
    end

    def x509_issue_crt_from_csr(cfg, csr)
      ca_crt, ca_key = get_ca_crt_and_key(cfg.fetch("ca"))

      crt = OpenSSL::X509::Certificate.new
      crt.version    = cfg.fetch("version", 3)
      crt.serial     = x509_random_serial
      crt.not_before = Time.now
      crt.not_after  = x509_not_after(cfg)
      crt.public_key = csr.public_key
      crt.subject    = csr.subject
      crt.issuer     = ca_crt.subject

      xf = OpenSSL::X509::ExtensionFactory.new
      xf.subject_certificate = crt
      xf.issuer_certificate = ca_crt
      crt.add_extension xf.create_extension("subjectKeyIdentifier", "hash")
      crt.add_extension xf.create_extension("basicConstraints", "CA:FALSE")
      crt.add_extension xf.create_extension(
        "keyUsage", "keyEncipherment,dataEncipherment,digitalSignature"
      )

      crt.sign ca_key, OpenSSL::Digest::SHA256.new
      crt
    end

    Rake::FileList["tests/fixtures/*.yml"].each do |f|
      cfg = load_cfg(f)
      fcrt = f.ext('.crt')
      ca = cfg.fetch("ca")
      if ca == true
        # Generating a CA certificate
        fkey = f.ext('.key')
        file fcrt => [fkey, f] do |t|
          key = open(fkey) {|io| OpenSSL::PKey.read(io) }
          crt = x509_make_ca_crt(cfg, key)
          write_pem(crt, fcrt)
        end
      elsif cfg.fetch("csr") == true
        # Generating a certificate from a CSR
        fcsr = f.ext(".csr")
        fcacrt = f.pathmap("%d/#{ca}.crt")
        fcakey = f.pathmap("%d/#{ca}.key")
        file fcrt => [fcsr, fcacrt, fcakey, f] do |t|
          ca_crt = open(fcacrt) {|io| OpenSSL::X509::Certificate.new(io.read) }
          ca_key = open(fcakey) {|io| OpenSSL::PKey.read(io) }
          csr = OpenSSL::X509::Request.new(File.read(fcsr))
          crt = x509_issue_crt_from_csr(cfg, csr)
          write_pem(crt, fcrt)
        end
      else
        raise "unhandled config format: #{f}"
      end

      task certs: fcrt
    end

    rule ".csr" => [".key", ".yml"] do |t|
      key = load_key(t.source)
      cfg = load_cfg(t.source.ext(".yml"))
      csr = x509_make_csr(cfg, key)
      write_pem(csr, t.name)
    end

    rule ".pub" => [".key", ".yml"] do |t|
      key = load_key(t.source)
      write_pem(key.public_key, t.name)
    end

    rule ".key" => [".aes-key", ".yml"] do |t|
      key = load_key(t.source, t.source.ext(".pass"))
      write_pem(key, t.name)
    end

    rule ".aes-key" => [".pass", ".yml"] do |t|
      cipher = OpenSSL::Cipher.new 'AES-128-CBC'
      passphrase = File.read(t.source)
      key = OpenSSL::PKey::RSA.new 2048
      write_pem(key, t.name, passphrase: passphrase)
    end

    rule ".pass" => ".yml" do |t|
      require "securerandom"
      open t.name, "w" do |io|
        io << SecureRandom.urlsafe_base64(128)
      end
    end

    rule "tests/fixtures/*" => "tests/fixtures"

  end

  task fixtures: "fixtures:certs"

end

task clean:   "test:fixtures:clean"
task clobber: "test:fixtures:clobber"

task test: "test:fixtures"
