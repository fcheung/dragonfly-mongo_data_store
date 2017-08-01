RSpec.configure do |config|
  config.before(:suite) do
    Mongo::Logger.logger.level = Logger::INFO
  end
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

