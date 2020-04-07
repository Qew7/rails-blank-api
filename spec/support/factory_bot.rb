RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.reload
    FactoryBot.define { to_create(&:save) }
  end
end
