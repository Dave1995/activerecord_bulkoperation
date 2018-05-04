mod = if RUBY_ENGINE == 'ruby'
  require_relative 'oci'

  Bulkoperation::ActiveRecord::BatchUpdate::Oci

elsif RUBY_ENGINE == 'jruby'
  require_relative 'jdbc'

  Bulkoperation::ActiveRecord::BatchUpdate::Jdbc

else
  fail "Unsupported RUBY_ENGGINE #{RUBY_ENGINE.inspect}"

end

ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter.include( mod )
