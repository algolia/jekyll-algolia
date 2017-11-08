module AlgoliaPlugin
  def self.do_something(config)
    site = Jekyll::Site.new(config)
    site.process
  end
end

describe 'AlgoliaPlugin' do
  it 'should create a new site with the config passed' do
    # Given
    config = { foo: 'bar' }

    # When
    AlgoliaPlugin.do_something(config)

    # Then
    # ??? 
    # expect(Jekyll::Site).to receive(:new).with(input) <= Does not work because
    # I haven't allowed listening to it
    #
    # mock_site = double('Jekyll::Site', process: nil)
    # allow(Jekyll::Site).to receive(:new).and_return(mock_site) <= Ok, I can
    # call the method without failing but the expect does not work
    #
    # Only thing that works is writing the full expect (including
    # with/and_return) from the start, but that has me writing my expectation at
    # the beginning...
    # 
  end
end
