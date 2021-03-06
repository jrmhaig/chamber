# frozen_string_literal: true

require 'rspectacular'
require 'chamber/filters/environment_filter'

module    Chamber
module    Filters
describe  EnvironmentFilter do
  it 'can extract data from the environment if an existing variable matches the ' \
     'composite key' do

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = 'value 2'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: 'value 1',
                                                  },
                                                },
                                              })

    test_setting  = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to eql 'value 2'

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'can extract an array from the environment if an existing variable' \
     'matches the composite key' do

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '[4, 5, 6]'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: [
                                                                    1,
                                                                    2,
                                                                    3,
                                                                  ],
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to eql [4, 5, 6]

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '["4", "5", "6"]'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: %w{1 2 3},
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to eql %w{4 5 6}

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'raises an error if the array value cannot be converted' do
    ENV['TEST_SETTING_GROUP_TEST_SETTING_ONE'] = '{"foobar": "bazqux"}'

    expect {
      EnvironmentFilter.execute(
        secure_key_prefix: '_secure_',
        data:              {
          test_setting_group: {
            test_setting_one: %w{1 2 3},
          },
        },
      )
    }.to \
      raise_error(ArgumentError)
        .with_message('Invalid value for Array: {"foobar": "bazqux"}')

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'does not affect items which are not stored in the environment' do
    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = 'value 2'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting:    'value 1',
                                                    another_setting: 'value 3',
                                                  },
                                                },
                                              })

    another_setting = filtered_data.test_setting_group.test_setting_level.another_setting

    expect(another_setting).to eql 'value 3'

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'can extract a nil from the environment if an existing variable' \
     'matches the composite key' do

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '___nil___'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: 1,
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to be nil

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '___null___'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: 1,
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to be nil

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'can extract an integer from the environment if an existing variable' \
     'matches the composite key' do

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '2'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: 1,
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to be 2

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'can extract a float from the environment if an existing variable' \
     'matches the composite key' do

    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '2.3'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: 1.2,
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to be 2.3

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'can extract a boolean from the environment if an existing variable' \
     'matches the composite key' do

    ENV['TEST_SETTING_GROUP_TEST_SETTING_ONE']   = 'false'
    ENV['TEST_SETTING_GROUP_TEST_SETTING_TWO']   = 'true'
    ENV['TEST_SETTING_GROUP_TEST_SETTING_THREE'] = 'f'
    ENV['TEST_SETTING_GROUP_TEST_SETTING_FOUR']  = 't'
    ENV['TEST_SETTING_GROUP_TEST_SETTING_FIVE']  = 'no'
    ENV['TEST_SETTING_GROUP_TEST_SETTING_SIX']   = 'yes'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_one:   true,
                                                  test_setting_two:   false,
                                                  test_setting_three: true,
                                                  test_setting_four:  false,
                                                  test_setting_five:  true,
                                                  test_setting_six:   false,
                                                  test_setting_seven: false,
                                                },
                                              })

    expect(filtered_data.test_setting_group.test_setting_one).to   be false
    expect(filtered_data.test_setting_group.test_setting_two).to   be true
    expect(filtered_data.test_setting_group.test_setting_three).to be false
    expect(filtered_data.test_setting_group.test_setting_four).to  be true
    expect(filtered_data.test_setting_group.test_setting_five).to  be false
    expect(filtered_data.test_setting_group.test_setting_six).to   be true
    expect(filtered_data.test_setting_group.test_setting_seven).to be false

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'raises an error if the boolean value cannot be converted' do
    ENV['TEST_SETTING_GROUP_TEST_SETTING_ONE'] = 'foobar'

    expect {
      EnvironmentFilter.execute(
        secure_key_prefix: '_secure_',
        data:              {
          test_setting_group: {
            test_setting_one: true,
          },
        },
      )
    }.to \
      raise_error(ArgumentError)
        .with_message('Invalid value for Boolean: foobar')

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end

  it 'returns the settings value if there is no environment variable to override it' do
    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: 1,
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to be 1
  end

  it 'returns the raw environment value if there is no conversion' do
    ENV['TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING'] = '2'

    filtered_data = EnvironmentFilter.execute(secure_key_prefix: '_secure_',
                                              data:              {
                                                test_setting_group: {
                                                  test_setting_level: {
                                                    test_setting: '1',
                                                  },
                                                },
                                              })

    test_setting = filtered_data.test_setting_group.test_setting_level.test_setting

    expect(test_setting).to eql '2'

    ENV.delete('TEST_SETTING_GROUP_TEST_SETTING_LEVEL_TEST_SETTING')
  end
end
end
end
