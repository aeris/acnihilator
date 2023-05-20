require './adblock'

RSpec.describe AdBlock, '#match?' do
  it 'must not block if no rules matches' do
    list = AdBlock.new
    list << '/banner/*/img^'
    list << '||ads.example.com^'
    expect(list.match? 'http://example.com/banner/img').to be_falsey
    expect(list.match? 'http://ads.example.com.ua/foo.gif').to be_falsey
  end

  it 'must block if any rules matches' do
    list  = AdBlock.new
    rule1 = list << '/banner/*/img^'
    rule2 = list << '||ads.example.com^'
    expect(list.match? 'http://example.com/banner/foo/img').to eq [rule1]
    expect(list.match? 'http://ads.example.com/foo.gif').to eq [rule2]
    expect(list.match? 'http://ads.example.com/banner/foo/img').to eq [rule1, rule2]
  end

  it 'must not block if exception' do
    list = AdBlock.new
    list << '/banner/*/img^'
    list << '@@||ads.example.com^'
    expect(list.match? 'https://ads.example.com:8080/banner/foo/img').to be_falsey
  end
end
