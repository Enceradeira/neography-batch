require 'spec_helper'

describe 'examples' do
  describe 'simple write and read' do
    it 'writes to neo4j and reads from neo4j' do

      # write some data
      batch = Neography::Composable::Batch.new
      batch << [:create_unique_node, 'person', 'name', 'john', {'age' => 33}]
      batch.submit()

      # read data
      read_batch = Neography::Composable::Batch.new
      read_batch << [:get_node_index, 'person', 'name', 'john']
      result = read_batch.submit()

      # test if it worked?
      expect(result).to have(1).item
      expect(result.first.first['data']).to eq({'age' => 33})
    end
  end
  describe 'simple write and read using a block for initialization' do
    it 'writes to neo4j and reads from neo4j' do

      # write & submit some data
      Neography::Composable::Batch.new do |b|
        b << [:create_unique_node, 'person', 'name', 'john', {'age' => 33}]
      end.submit()

      # read & submit
      result = Neography::Composable::Batch.new do |b|
        b << [:get_node_index, 'person', 'name', 'john']
      end.submit()

      # test if it worked?
      expect(result).to have(1).item
      expect(result.first.first['data']).to eq({'age' => 33})
    end
  end
  describe 'aggregating two batches into one' do
    it 'writes all data in one batch/transaction' do

      batch1 = Neography::Composable::Batch.new do |b|
        b << [:create_unique_node, 'person', 'name', 'john', {'age' => 33}]
        b << [:create_unique_node, 'person', 'name', 'carl', {'age' => 45}]
      end

      batch2 = Neography::Composable::Batch.new do |b|
        b << [:create_unique_node, 'salary', 'employee', 'john', {'wage' => 1200}]
        b << [:create_unique_node, 'salary', 'employee', 'carl', {'wage' => 1055}]
      end

      # combining the two batches and submitting it in one transfer/transaction
      super_batch = batch1 << batch2
      super_batch.submit()

      # test if it worked?
      result = Neography::Composable::Batch.new do |b|
        b << [:get_node_index, 'person', 'name', 'john']
        b << [:get_node_index, 'person', 'name', 'carl']
        b << [:get_node_index, 'salary', 'employee', 'john']
        b << [:get_node_index, 'salary', 'employee', 'carl']
      end.submit()

      expect(result).to have(4).items
      expect(result[0][0]['data']).to eq({'age' => 33})
      expect(result[1][0]['data']).to eq({'age' => 45})
      expect(result[2][0]['data']).to eq({'wage' => 1200})
      expect(result[3][0]['data']).to eq({'wage' => 1055})
    end
  end
end