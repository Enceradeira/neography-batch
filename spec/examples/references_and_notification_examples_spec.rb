require 'spec_helper'

describe 'references and notification examples' do
  let(:neo) { Neography::Rest.new }
  let(:root) { neo.get_root }

  describe 'referencing nodes from different batches' do
    it 'works perfectly' do
      # creating a company
      company_batch = Neography::Composable::Batch.new
      ibm = company_batch << [:create_node, {'name' => 'IBM'}]
      company_batch << [:create_relationship, 'company', root, ibm]

      # create some persons
      persons_batch = Neography::Composable::Batch.new
      john = persons_batch << [:create_node, {'name' => 'john'}]
      lucy = persons_batch << [:create_node, {'name' => 'lucy'}]

      # connect persons with company
      hr_batch = Neography::Composable::Batch.new
      hr_batch << [:create_relationship, 'employee', ibm, john]
      hr_batch << [:create_relationship, 'employee', ibm, lucy]

      # query the inserted nodes
      query_batch = Neography::Composable::Batch.new
      query_batch << [:execute_query, 'start r=node(0) match r-[:company]->c-[:employee]->e return e.name']

      # join batches and execute all in one go
      super_batch = company_batch << persons_batch << hr_batch << query_batch
      result = super_batch.submit()

      # test if it worked?
      query_result = result.last['data'].map { |r| r.first }
      expect(query_result).to include('john')
      expect(query_result).to include('lucy')
    end
  end

  describe 'notification after submitting a command' do
    it 'notifies reference with result returned from server' do
      johns_id = nil

      batch = Neography::Composable::Batch.new
      john = batch << [:create_node, {'name' => 'john'}]

      # ask for being notified after submit
      john.after_submit do |n|
        johns_id = get_id(n)
      end

      batch.submit()

      # test if it worked?
      johns_node = neo.get_node(johns_id)
      expect(johns_node['data']['name']).to eq('john')
    end
  end
end
