
def fixture_path
  File.expand_path("../../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + '/' + file)
end

def raw_fixture(file)
  fixture(file).read
end

def json_fixture(file)
  JSON.parse(fixture(file).read)
end