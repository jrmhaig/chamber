# frozen_string_literal: true

require 'thor'
require 'chamber/rubinius_fix'
require 'chamber/commands/show'
require 'chamber/commands/files'
require 'chamber/commands/secure'
require 'chamber/commands/unsecure'
require 'chamber/commands/sign'
require 'chamber/commands/verify'
require 'chamber/commands/compare'
require 'chamber/commands/initialize'

module  Chamber
module  Binary
class   Runner < Thor
  include Thor::Actions

  source_root ::File.expand_path('../../../templates', __dir__)

  class_option  :rootpath,
                type:    :string,
                aliases: '-r',
                default: ENV.fetch('PWD', nil),
                desc:    'The root filepath of the application'

  class_option  :basepath,
                type:    :string,
                aliases: '-b',
                desc:    'The base filepath where Chamber will look for the ' \
                         'conventional settings files'

  class_option  :files,
                type:    :array,
                aliases: '-f',
                desc:    'The set of file globs that Chamber will use for processing'

  class_option  :namespaces,
                type:    :array,
                aliases: '-n',
                default: [],
                desc:    'The set of namespaces that Chamber will use for processing'

  class_option  :preset,
                type:    :string,
                aliases: '-p',
                enum:    %w{rails},
                desc:    'Used to quickly assign a given scenario to the chamber ' \
                         'command (eg Rails apps)'

  class_option  :decryption_keys,
                type: :array,
                desc: 'The path to or contents of the private key (or keys) associated ' \
                      'with the project (typically .chamber.pem)'

  class_option  :encryption_keys,
                type: :array,
                desc: 'The path to or contents of the public key (or keys) associated ' \
                      'with the project (typically .chamber.pub.pem)'

  ################################################################################

  desc 'show', 'Displays the list of settings and their values'

  method_option :as_env,
                type:    :boolean,
                aliases: '-e',
                desc:    'Whether the displayed settings should be environment ' \
                         'variable compatible'

  method_option :only_sensitive,
                type:    :boolean,
                aliases: '-s',
                desc:    'Only displays the settings that are/should be secured. ' \
                         'Useful for debugging.'

  def show
    puts Commands::Show.call(**options.transform_keys(&:to_sym).merge(shell: self))
  end

  ################################################################################

  desc 'files', 'Lists the settings files which are parsed with the given options'

  def files
    puts Commands::Files.call(**options.transform_keys(&:to_sym).merge(shell: self))
  end

  ################################################################################

  desc 'compare',
       'Displays the difference between the settings in the first set ' \
       'of namespaces and the settings in the second set.  Useful for ' \
       'tracking down why there may be issues in development versus test ' \
       'or differences between staging and production.'

  method_option :keys_only,
                type:    :boolean,
                default: true,
                desc:    'Whether or not to only compare the keys but not the values ' \
                         'of the two sets of settings'

  method_option :first,
                type:     :array,
                required: true,
                desc:     'The list of namespaces which will be used as the source of ' \
                          'the comparison'

  method_option :second,
                type:     :array,
                required: true,
                desc:     'The list of namespaces which will be used as the ' \
                          'destination of the comparison'

  def compare
    Commands::Compare.call(**options.transform_keys(&:to_sym).merge(shell: self))
  end

  ################################################################################

  desc 'secure',
       'Secures any values which appear to need to be encrypted in any of ' \
       'the settings files which match irrespective of namespaces'

  method_option :only_sensitive,
                type:    :boolean,
                default: true

  method_option :dry_run,
                type:    :boolean,
                aliases: '-d',
                desc:    'Does not actually encrypt anything, but instead displays ' \
                         'what values would be encrypted'

  def secure
    Commands::Secure.call(**options.transform_keys(&:to_sym).merge(shell: self))
  end

  ################################################################################

  desc 'unsecure',
       'Decrypts all encrypted values using the current key(s)' \

  method_option :dry_run,
                type:    :boolean,
                aliases: '-d',
                desc:    'Does not actually decrypt anything, but instead displays ' \
                         'what values would be decrypted'

  def unsecure
    Commands::Unsecure.call(**options.transform_keys(&:to_sym).merge(shell: self))
  end

  ################################################################################

  desc 'sign',
       'Creates or verifies signatures for all current settings files using ' \
       'the signature private key.'

  method_option :verify,
                type:    :boolean,
                default: false

  method_option :signature_name,
                type:    :string,
                default: `git config --get 'user.name'`.chomp

  def sign
    if options[:verify]
      Commands::Verify.call(**options.transform_keys(&:to_sym).merge(shell: self))
    else
      Commands::Sign.call(**options.transform_keys(&:to_sym).merge(shell: self))
    end
  end

  ################################################################################

  desc 'init',
       'Sets Chamber up using best practices for secure configuration management'

  method_option :signature,
                type:    :boolean,
                default: false

  def init
    Commands::Initialize.call(**options.transform_keys(&:to_sym).merge(shell: self))
  end
end
end
end
