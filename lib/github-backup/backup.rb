module GithubBackup
  class Backup
    attr_reader :debug, :username, :client, :config

    def initialize(username, options = {})
      @username    = username
      @debug       = false
      @config      = Config.new(options)
      @client      = Octokit::Client.new(:access_token => config.token)
    end

    def execute
      backup_all
    rescue Octokit::Unauthorized
      puts "Github API authentication failed."
      puts "Please add a [github] section to your ~/.gitconfig"
      puts "  See: http://github.com/guides/tell-git-your-user-name-and-email-address"
      puts "Or, use the arguments to authenticate with your username and API token."
    end

    private

    def backup_all
      FileUtils::mkdir_p(config.backup_root)
      repositories.each do |repository|
        puts "Backing up: #{repository.full_name}"
        args = { clone_url: repository.ssh_url,
                 backup_path: backup_directory_for(repository) }
        GithubBackup::Repository.new(args).backup
      end
    end

    def repositories
      GithubBackup::GithubRepositoryCollection.
        new(client).
          repos(username)
    end

    def backup_directory_for(repository)
      File.join(config.backup_root, repository.full_name) + '.git'
    end

  end
end
