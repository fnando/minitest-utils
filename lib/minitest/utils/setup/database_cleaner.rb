DatabaseCleaner[:active_record].strategy = :deletion

module Minitest
  class Test
    setup do
      DatabaseCleaner.clean
    end
  end
end
