module Porthos
  def benchmark
    cur = Time.now
    result = yield
    print "#{cur = Time.now - cur} seconds"
    puts " (#{(cur / $last_benchmark * 100).to_i - 100}% change)" rescue puts ""
    $last_benchmark = cur
    result
  end
end
require 'porthos/access_controll'
require 'porthos/model_restrictions'
require 'porthos/routing'
require 'porthos/acts_as_taggable'
require 'porthos/validators'
require 'porthos/acts_as_settingable'
require 'porthos/acts_as_filterable'