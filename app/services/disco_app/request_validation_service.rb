class DiscoApp::RequestValidationService

  def self.hmac_valid?(query_string, secret)
    Rails.logger.info "query_string: #{query_string}"
    query_hash = Rack::Utils.parse_query(query_string)
    Rails.logger.info "query_hash: #{query_hash}"
    hmac = query_hash.delete('hmac').to_s

    Rails.logger.info "Validating HMAC for query_string: #{query_string}"
    get_calculated_hmac = calculated_hmac(query_hash, secret)
    Rails.logger.info "Calculated HMAC: #{get_calculated_hmac}, Provided HMAC: #{hmac}"
    
    ActiveSupport::SecurityUtils.secure_compare(get_calculated_hmac, hmac)
  end

  def self.calculated_hmac(query_hash, secret)
    sorted_params = query_hash.map { |k, v| "#{k}=#{Array(v).join(',')}" }.sort.join('&')
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, sorted_params)
  end
end
