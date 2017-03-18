## EventMachine Nedir? ##

EventMachine Ruby için olay-güdümlü G/Ç ve hafif koşut zamanlı (concurrency) kütüphanesidir. 
[JBoss Netty](http://www.jboss.org/netty), [Apache MINA](http://mina.apache.org/),
Python's [Twisted](http://twistedmatrix.com), [Node.js](http://nodejs.org), libevent ve libev kitaplıkları gibi [Reaktör desenini](http://en.wikipedia.org/wiki/Reactor_pattern) kullanarak olay-güdümlü G/Ç'a imkan verir.

EventMachine iki anahtar gereksinimi karşılamak için tasarlanmıştır:

* Çoğu son kullanıcı ürünlerin gerektirdiği oldukça yüksek ölçeklenebilirlik, performans ve kararlılık

* Yüksek performanslı zincirlenmiş (threaded) ağ programlamanın karmaşıklığını gizleyecek API, mühendislerin uygulamanın kendisine odaklanmalarını sağlar.

Bu eşsiz birleşim, Web sunucuları ve vekilleri (proxies), eposta ve IM son kullanıcı sistemleri, doğrulama/yetkilendirme süreçleri ve burada sayamayacağımız kadar çok kritik ağ uygulamalarının tasarımında EventMachine'i ana seçenek yapar.

EventMachine 2000'lerden bu yana aramızdadır, oturmuş ve ciddi-testlerden geçmiş bir kitaplıktır.


## EventMachine ne için iyidir? ##

* Ölçeklenebilir olay-güdümlü sunucular. Örneğin [Thin](http://code.macournoyer.com/thin/) veya [Goliath](https://github.com/postrank-labs/goliath/).
* Farklı protokoller, RESTful API'ler vb için ölçeklenebilir asenkron istemciler. Örneğin: [em-http-request](https://github.com/igrigorik/em-http-request) veya [amqp gem](https://github.com/ruby-amqp/amqp).
* Özelleştirilmiş etkili ağ vekilleri. Örneğin: [Proxymachine](https://github.com/mojombo/proxymachine/).
* Dosya ve ağ izleme araçları. Örneğin: [eventmachine-tail](https://github.com/jordansissel/eventmachine-tail) ve [logstash](https://github.com/logstash/logstash).


## EventMachine hangi platformları destekler? ##

EventMachine, Ruby 1.8.7-2.3, REE, JRuby'i destekler Unix ailesinden çoğu işletim sisteminin (Linux, Mac OS X, BSD) yanı sıra **Windows'da bile iyi çalışır**.

## Gem'i kurmak ##

[RubyGems](https://rubygems.org/) ile kurabiliriz

```sh
gem install eventmachine
```

veya [Bundler](http://gembundler.com/) kullanıyorsanız `Gemfile`'a ekleyebiliriz:

```ruby
gem "eventmachine"
```

## Başlangıç ##

EventMachine ile tanışmak için aşağıdaki kaynaklara bakabilirsiniz:

* [Ilya Grigorik'in EventMachine hakkında ki blog girdisi](http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/).
* [Dan Sinclair tarafından hazırlanmış EventMachine'a Giriş](http://everburning.com/news/eventmachine-introductions.html).

### Sunucu örneği: Yankı sunucu ###

EventMachine ile yazılmış tam donanımlı yankı (echo) sunucu:

```ruby
 require 'eventmachine'

 module EchoServer
   def post_init
     puts "-- birisi yankı sunucuya bağlandı!"
   end

   def receive_data data
     send_data ">>>Gönderiniz: #{data}"
     close_connection if data =~ /quit/i
   end

   def unbind
     puts "-- birisi yankı sunucudan ayrıldı!"
   end
end

# Bunun şu an ki iş sürecini (thread) bloke edecek.
EventMachine.run {
  EventMachine.start_server "127.0.0.1", 8081, EchoServer
}
```


## EventMachine rehberi ##

Şimdilik [referans rehberine](http://rdoc.info/github/eventmachine/eventmachine/frames) ve [wiki](https://github.com/eventmachine/eventmachine/wiki)'ye sahibiz.

## Topluluk ve yardım alma yolu ##

* [Posta listesine](http://groups.google.com/group/eventmachine) (Google Group) katıl
* irc.freenode.net de ki IRC kanalına #eventmachine katıl.


## Lisans ve telif ##

EventMachine  ya GPL ya da Ruby Lisansının taşıdığı ücretsiz yazılım telif hakkına sahiptir.

Telif: Francis Cianfrocca (C) 2006-07. Tüm hakları saklıdır.


## Alternatifler ##

Ruby kullanıcısıysanız ve EventMachine sizi mutlu edemediyse, [Celluloid](https://celluloid.io/) ilginizi çekebilir.
