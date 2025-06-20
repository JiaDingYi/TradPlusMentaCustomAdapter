Pod::Spec.new do |s|
    s.name             = 'TradPlusMentaCustomAdapter'
    s.version          = '1.0.0'
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
  
  end
  