require './adblock'

RSpec.describe AdBlock::Rule, '#match?' do
  it 'must block by address part' do
    rule = AdBlock::Rule.new '/banner/*/img^'

    expect(rule.match? 'http://example.com/banner/foo/img').to be true
    expect(rule.match? 'http://example.com/banner/foo/bar/img?param').to be true
    expect(rule.match? 'http://example.com/banner//img/foo').to be true

    expect(rule.match? 'http://example.com/banner/img').to be false
    expect(rule.match? 'http://example.com/banner/foo/imgraph').to be false
    expect(rule.match? 'http://example.com/banner/foo/img.gif').to be false
  end

  it 'must block by domain name' do
    rule = AdBlock::Rule.new '||ads.example.com^'

    expect(rule.match? 'http://ads.example.com/foo.gif').to be true
    expect(rule.match? 'http://server1.ads.example.com/foo.gif').to be true
    expect(rule.match? 'https://ads.example.com:8000/').to be true

    expect(rule.match? 'http://ads.example.com.ua/foo.gif').to be false
    expect(rule.match? 'http://example.com/redirect/http://ads.example.com/').to be false
  end

  it 'must block by exact address' do
    rule = AdBlock::Rule.new '|http://example.com/|'

    expect(rule.match? 'http://example.com/').to be true

    expect(rule.match? 'http://example.com/foo.gif').to be false
    expect(rule.match? 'http://example.info/redirect/http://example.com/').to be false
  end

  it 'must not block exception' do
    rule = AdBlock::Rule.new '@@/banner/*/img^'

    expect(rule.match? 'http://example.com/banner/foo/img').to be :exception
    expect(rule.match? 'http://example.com/banner/foo/bar/img?param').to be :exception
    expect(rule.match? 'http://example.com/banner//img/foo').to be :exception

    expect(rule.match? 'http://example.com/banner/img').to be false
    expect(rule.match? 'http://example.com/banner/foo/imgraph').to be false
    expect(rule.match? 'http://example.com/banner/foo/img.gif').to be false
  end
end
