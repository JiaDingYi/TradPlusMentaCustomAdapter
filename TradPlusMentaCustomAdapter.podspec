Pod::Spec.new do |s|
    s.name             = 'TradPlusMentaCustomAdapter'
    s.version          = '1.0.20.1'
    s.summary          = 'TradPlusMentaCustomAdapter.'
    s.description      = 'A short description of TradPlusMentaCustomAdapter.'
    s.homepage         = 'https://github.com/jdy'
    s.license          = "Custom"
    s.author           = { 'jdy' => 'wzy2010416033@163.com' }
    s.source           = { :git => "git@github.com:JiaDingYi/TradPlusMentaCustomAdapter.git", :tag => "#{s.version}"}
  
    s.static_framework = true
    s.ios.deployment_target = '11.0'
    s.source_files = 'TradPlusMentaCustomAdapter/**/*'
    
    s.dependency 'TradPlusAdSDK'
    s.dependency 'TradPlusAdSDK/TPCrossAdapter'
    s.dependency 'MentaVlionGlobal',         '~> 1.0.20'
    s.dependency 'MentaMediationGlobal',     '~> 1.0.20'
    s.dependency 'MentaVlionGlobal',         '~> 1.0.20'
    s.dependency 'MentaVlionGlobalAdapter',  '~> 1.0.20'
  
  end
  
