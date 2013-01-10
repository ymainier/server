cookbook_path File.expand_path(File.join(File.dirname(__FILE__), "cookbooks"))
http_proxy "http://proxy.travelcom.michelin-travel.com:8080"
https_proxy "http://proxy.travelcom.michelin-travel.com:8080"
no_proxy "localhost,127.0.0.1,*.local,169.254/16,atafu.travelcom.michelin-travel.com,musha.travelcom.michelin-travel.com,mac22"
