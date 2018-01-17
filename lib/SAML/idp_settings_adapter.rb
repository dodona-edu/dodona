class IdPSettingsAdapter
  def self.settings(idp_entity_id)
    case idp_entity_id
    when "UGent"
      {
        idp_slo_target_url: "https://ideq.ugent.be/simplesaml/saml2/idp/SingleLogoutService.php",
        idp_sso_target_url: "https://ideq.ugent.be/simplesaml/saml2/idp/SSOService.php",
        idp_cert: <<-CERT.chomp
  MIIFMDCCBBigAwIBAgIQAy7rsc3GwUd4Cmd35/hqQjANBgkqhkiG9w0BAQsFADBkMQswCQYDVQQGEwJOTDEWMBQGA1UECBMNTm9vcmQtSG9sbGFuZDESMBAGA1UEBxMJQW1zdGVyZGFtMQ8wDQYDVQQKEwZURVJFTkExGDAWBgNVBAMTD1RFUkVOQSBTU0wgQ0EgMzAeFw0xNTA4MDUwMDAwMDBaFw0xODA4MDkxMjAwMDBaMIGDMQswCQYDVQQGEwJCRTEYMBYGA1UECBMPT29zdC1WbGFhbmRlcmVuMQ0wCwYDVQQHEwRHZW50MRowGAYDVQQKExFVbml2ZXJzaXRlaXQgR2VudDEXMBUGA1UECxMORGFubnkgQm9sbGFlcnQxFjAUBgNVBAMTDWlkZXEudWdlbnQuYmUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsvNQsxWZLzB4tQ69M8NQv9i7J8t7ybfzN+eOIUwikTEMGmdLqNwab6MTJJEPl0RpxzDzc7sky5ysYOzAw6qa95/6Apnl3MLqXa8C+yYTLz5kxbA+7xJ16mGm1tHem9cusimfvLDTBYjLHGMTxvJOwDUG78KlT5CfJ2oSNYcyx9AI4z9TeccJz2nTKitYEQHjgXCQl+5z5wnPkU97YQWDQ6+c0oRo/6Q1jzL2fP4IG23YSAS0FTY2ntzVIEQl04yLv/iKVo5RpVj9iTTLX/QIp61LtsgC0Q2pIAp5OaAJoJ+SgxOTEUDMuEIuUi2pcpJDs4/7SIJxT4yQ6r9lT8lo3AgMBAAGjggG8MIIBuDAfBgNVHSMEGDAWgBRn/YggFCeYxwnSJRm76VERY3VQYjAdBgNVHQ4EFgQUYpS3fBMuqU0oAvI6354A6LP/NhowGAYDVR0RBBEwD4INaWRlcS51Z2VudC5iZTAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMGsGA1UdHwRkMGIwL6AtoCuGKWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9URVJFTkFTU0xDQTMuY3JsMC+gLaArhilodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vVEVSRU5BU1NMQ0EzLmNybDBCBgNVHSAEOzA5MDcGCWCGSAGG/WwBATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMG4GCCsGAQUFBwEBBGIwYDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMDgGCCsGAQUFBzAChixodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vVEVSRU5BU1NMQ0EzLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQCDuCU49W/+o10SSmq8gEHAD0CJIRR3wfTQZ3SObS7tuKfuT0kwcmWVvja3OzmH9MlX0aLa4lEaWkb6JAUUQexSPutgbv/mgU11YVnadDMcRIiC3L2sftlcSYLlayqBnOAQHm/5T/VV5rOrPUA2yarN8eg9PMqciE628obp2ujaLFmiecw3hT+N/laQbE2i0x6bCq3lgzSo3jOp/DAj78mplMkHVJv/dVgqzxkRKTzM1qYJcrcmJPS/Cuem89H8upodvT35Rag8xQqQDRLGA/UI7K4YLhQwotGpcnYAbz3vMhScwCLJdsz04d/d6Gm0SQkK3hzsuIFx0G69u/8/fbGi
        CERT
      }
    when "UHasselt"
      {
        idp_slo_target_url: "http://another_idp_slo_target_url.com",
        idp_sso_target_url: "http://another_idp_sso_target_url.com",
        idp_cert: "another_idp_cert"
      }
    else
      {}
    end
  end

  def self.entity_id(params)
    params[:idp]
  end
end
