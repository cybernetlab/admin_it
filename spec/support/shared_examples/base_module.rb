=begin
shared_examples 'Base module' do
  it 'accepts including only into WrapIt::Base' do
    mod = described_class
    expect do
      Class.new(WrapIt::Base) { include mod }
    end.to raise_error TypeError, /only into WrapIt::Base/
  end
end
=end
