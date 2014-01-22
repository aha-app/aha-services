def stub_download_feature_attachments
  # Download attachments.
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6cce987f6283d15c080e53bba15b1072a7ab5b07/original.png?1370457053").
    to_return(:status => 200, :body => "aaaaaa", :headers => {})
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/d1cb788065a70dad7ba481c973e19dcd379eb202/original.png?1370457055").
    to_return(:status => 200, :body => "bbbbbb", :headers => {})
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/80641a3d3141ce853ea8642bb6324534fafef5b3/original.png?1370458143").
    to_return(:status => 200, :body => "cccccc", :headers => {})
  stub_request(:get, "https://attachments.s3.amazonaws.com/attachments/6fad2068e2aa0e031643d289367263d3721c8683/original.png?1370458145").
    to_return(:status => 200, :body => "dddddd", :headers => {})
end