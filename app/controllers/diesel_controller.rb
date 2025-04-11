class DieselController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create_server, :update_server, :delete_server, :get_server]
  skip_before_action :login_required
  before_action :verify_password

  def create_server
    @server = @org.servers.build(server_params)
    @server.privacy_mode = false
    @server.log_smtp_data = false
    @server.allow_sender = true
    @server.spam_threshold = 3.0
    @server.spam_failure_threshold = 20.0
    if @server.save
      @domain = @server.domains.build(
        domain_params.merge(
          verification_method: "DNS",
          verified_at: Time.now
        )
      )
      if @domain.save
        @credential = @server.credentials.create(
          name: @server.permalink,
          type: "SMTP"
        )
        @http_endpoint = @server.http_endpoints.create(
          name: "Diesel",
          url: "https://dieseltms.com/postal/inbound/#{@server.permalink}",
          encoding: "BodyAsJSON",
          format: "Hash",
          strip_replies: false,
          include_attachments: true,
          timeout: 20
        )
        @smtp_endpoint = @server.smtp_endpoints.create(
          name: "Diesel",
          hostname: "postal.dieseltms.com",
          ssl_mode: "Auto",
          port: 2525
        )
        @route = @server.routes.create(
          domain_id: @domain.id,
          endpoint_id: @smtp_endpoint.id,
          endpoint_type: "SMTPEndpoint",
          name: "*",
          spam_mode: "Quarantine",
          mode: "Endpoint"
        )

        render json: @server.as_json(include: [:domains, :credentials, :http_endpoints, :smtp_endpoints, :routes])
      else
        render json: { error: "Failed to create domain. Please check the domain name and try again." }, status: :unprocessable_entity, status: 422
      end
    else
      render json: { error: "Failed to create server. Please check the server details and try again." }, status: :unprocessable_entity, status: 422
    end
  end

  def update_server
    @server = Server.find(params[:server][:id])
  end

  def delete_server
    @server = Server.find(params[:server][:id])
    @server&.destroy
  end
  
  def get_server
    @server = Server.joins(:domains).find_by("servers.id": params[:server][:id], "domains.id": params[:domain][:id])
    if @server.present?
      @domain = @server.domains.first
      render json: @server.as_json(include: [:domains, :credentials, :http_endpoints, :smtp_endpoints, :routes])
      # if @domain.verified?
      # else
      #   render json: { error: "Failed to verify domain. Please check your DNS records." }, status: :unprocessable_entity, status: 422
      # end
    else
      render json: { error: "Server doesn't exist. Please check the domain name and try again." }, status: :not_found
    end
  end

  def server_params
    @server_params ||=
      params.
        require(:server).
        permit(
          :name, # account.name
          :permalink, # account.id
          :mode # "Live"
        )
  end

  def domain_params
    @domain_params ||= params.require(:domain).permit(:name)
  end

  def verify_password
    return if %w[23.122.17.161 54.226.25.129 172.31.0.244].include?(request.remote_ip) && params[:password] == "AtsyUApEZUyTTvTVCfOu"

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

end