module AlgoliaPlugin
  def self.do_something(config)
    site = Jekyll::Site.new(config)
    site.process
    42
  end
end

describe AlgoliaPlugin do
  describe '.do_something' do
    let(:config) { {foo: 'bar'} }
    let(:jekyll_site) { double('Jekyll::Site', process: nil) }
    before { expect(Jekyll::Site).to receive(:new).with(config).and_return(jekyll_site) }
    before { expect(jekyll_site).to receive(:process) }

    it { AlgoliaPlugin.do_something(config) }

  end
  describe '.do_something' do
    let(:config) { {foo: 'bar'} }
    let(:jekyll_site) { double('Jekyll::Site', process: nil) }
    before { allow(Jekyll::Site).to receive(:new).and_return(jekyll_site) }
    before { allow(jekyll_site).to receive(:process) }

    before { AlgoliaPlugin.do_something(config) }

    it { expect(Jekyll::Site).to have_received(:new).with(config) }
    it { expect(jekyll_site).to have_received(:process).with(config) }


  end
  describe '.do_something' do
    let(:config) { {foo: 'bar'} }
    let(:jekyll_site) { double('Jekyll::Site', process: nil) }
    before { allow(Jekyll::Site).to receive(:new).and_return(jekyll_site) }
    before { allow(jekyll_site).to receive(:process) }

    subject { AlgoliaPlugin.do_something(config) }

    context 'config is valid' do
      let(:config) { false }
      it { should eq 42 }
      it { expect(subject).to eq 42 }
    end
  end
end
