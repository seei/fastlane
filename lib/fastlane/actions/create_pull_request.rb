module Fastlane
  module Actions
    module SharedValues
      CREATE_PULL_REQUEST_HTML_URL = :CREATE_PULL_REQUEST_HTML_URL
    end

    class CreatePullRequestAction < Action
      def self.run(params)
        require 'excon'
        require 'base64'

        repo = params[:repo]
        head = params[:head] || Actions.git_branch
        base = params[:base] || 'master'

        Helper.log.info "Creating new pull request from '#{head}' to branch '#{base}' of '#{repo}'"

        url = "https://api.github.com/repos/#{repo}/pulls"
        headers = { 'User-Agent' => 'fastlane-create_pull_request' }
        headers['Authorization'] = "Basic #{Base64.strict_encode64(params[:api_token])}" if params[:api_token]

        body = {
          'title' => title = params[:title],
          'head' => head,
          'base' => base
        }

        body['body'] = params[:body] if params[:body]

        response = Excon.post url, headers: headers, body: body.to_json

        if response[:status] == 201
          body = JSON.parse response.body
          number = body['number']
          html_url = body['html_url']
          Helper.log.info "Successfully created pull request ##{number}. You can see it at '#{html_url}'".green

          Actions.lane_context[SharedValues::CREATE_PULL_REQUEST_HTML_URL] = html_url
        else
          if response[:status] != 200
            Helper.log.error "GitHub responded with #{response[:status]}:#{response[:body]}".red
          end
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "This will create a new pull request on GitHub"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "GITHUB_PULL_REQUEST_API_TOKEN",
                                       description: "Personal API Token for GitHub - generate one at https://github.com/settings/tokens",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :repo,
                                       env_name: "GITHUB_PULL_REQUEST_REPO",
                                       description: "The name of the repository you want to submit the pull request to",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :title,
                                       env_name: "GITHUB_PULL_REQUEST_TITLE",
                                       description: "The title of the pull request",
                                       is_string: true,
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :body,
                                       env_name: "GITHUB_PULL_REQUEST_BODY",
                                       description: "The contents of the pull request",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :head,
                                       env_name: "GITHUB_PULL_REQUEST_HEAD",
                                       description: "The name of the branch where your changes are implemented (defaults to the current branch name)",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :base,
                                       env_name: "GITHUB_PULL_REQUEST_BASE",
                                       description: "The name of the branch you want your changes pulled into (defaults to `master`)",
                                       is_string: true,
                                       optional: true)
        ]
      end

      def self.author
        "seei"
      end

      def self.is_supported?(platform)
        return true
      end
    end
  end
end
