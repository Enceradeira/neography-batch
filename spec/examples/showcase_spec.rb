require 'spec_helper'

describe 'showcase' do
  it 'shows essential futures' do
    batch_1 = Neography::Composable::Batch.new
    john = batch_1 << [:create_node, {'name' => 'john'}]

    batch_2 = Neography::Composable::Batch.new
    lucy = batch_2 << [:create_node, {'name' => 'lucy'}]

    batch_3 = Neography::Composable::Batch.new
    batch_3 << [:create_relationship, 'friend_of', john, lucy]

    super_batch = batch_1 << batch_2 << batch_3
    super_batch.submit()
  end
end
