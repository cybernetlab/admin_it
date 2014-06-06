module AdminIt
  # Sign urls for s3
  class SignedUrlController < AdminIt.config.controller
    before_filter :authenticate_user!

    def index
      render json: {
        policy: s3_upload_policy_document,
        signature: s3_upload_signature,
        key: "uploads/#{SecureRandom.uuid}/#{params[:doc][:title]}",
        success_action_redirect: '/'
      }
    end

    private

    # generate the policy document that amazon is expecting.
    def s3_upload_policy_document
      Base64.encode64(
        {
          expiration: 15.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
          conditions: [
            { bucket: AdminIt.config.s3[:bucket] },
            { acl: 'public-read' },
            ['starts-with', '$key', 'uploads/'],
            { success_action_status: '201' }
          ]
        }.to_json
      ).gsub(/\n|\r/, '')
    end

    # sign our request by Base64 encoding the policy document.
    def s3_upload_signature
      Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          AdminIt.config.s3[:secret_access_key],
          s3_upload_policy_document
        )
      ).gsub(/\n/, '')
    end
  end
end
