require 'spec_helper'

describe 'examples' do
  describe 'referencing nodes from different batches' do
    let(:root) { Neography::Rest.new.get_root }

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
      query_batch << [:execute_query,'start r=node(0) match r-[:company]->c-[:employee]->e return e.name']

      super_batch = company_batch << persons_batch << hr_batch << query_batch
      result = super_batch.submit()

      # test if it worked?
      names = result.last['data'].map{|r| r.first}
      expect(names).to include('john')
      expect(names).to include('lucy')
    end
  end

  describe 'notification after submitting a command' do

  end
end
