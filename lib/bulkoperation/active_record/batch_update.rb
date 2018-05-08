module Bulkoperation::ActiveRecord::BatchUpdate
end

if RUBY_ENGINE == 'ruby'
  require_relative 'batch_update/oci'

elsif RUBY_ENGINE == 'jruby'
  require_relative 'batch_update/jdbc'

else
  fail "Unsupported RUBY_ENGGINE #{RUBY_ENGINE.inspect}"

end