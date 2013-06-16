require_relative 'spec_helper'

class Function
  def self.persist_inserts(elements)
    batch = Batch.new
    elements.each do |e|
      batch << [:create_node, e]
    end
    return batch
  end
end

def create_batches(command1, command2, command3)
  batch1 = Batch.new do |b|
    b<<command1
  end

  batch2 = Batch.new do |b|
    b<<command2
  end

  batch3 = Batch.new do |b|
    b<<command3
  end
  return batch1, batch2, batch3
end

describe "Batch" do
  let(:db) { Neography::Rest.new }
  subject { Batch.new(db) }

  describe "new" do
    it "should create unit when no block provided" do
      Batch.new.should == Batch.unit()
    end
    it "should call block with itself when block is provided" do
      command = [:command]
      batch_configured_without_block = Batch.new
      batch_configured_without_block << command

      batch_with_block = Batch.new do |b|
        b << command
      end

      batch_with_block.should == batch_configured_without_block
    end
  end

  describe "==" do
    specify { (Batch.new==Batch.new).should be_true }
    specify { (Batch.new==[]).should be_false }
    specify do
      command1 = [:command_1]
      command2 = [:command_2]
      batch1 = Batch.new do |b|
        b << command1
        b << command2
      end
      batch2 = Batch.new do |b|
        b << command1
        b << command2
      end
      (batch1==batch2).should be_true
    end
    specify do
      batch1 = Batch.new do |b|
        b << [:command_1]
        b << [:command_2]
      end
      batch2 = Batch.new do |b|
        b << [:command_2]
        b << [:command_1]
      end
      (batch1==batch2).should be_false
    end
    specify do
      batch1 = Batch.new do |b|
        b << [:command_1, {:id => 7}]
        b << [:command_2, {:id => 9}]
      end
      batch2 = Batch.new do |b|
        b << [:command_1, {:id => 7}]
        b << [:command_2, {:id => 8}]
      end
      (batch1==batch2).should be_false
    end
    specify do
      batch1 = Batch.new { |b| b << [:command_1] }
      batch2 = Batch.new { |b| b << [:command_2] }
      (batch1==batch2).should be_false
    end
    specify do
      batch1 = Batch.new { |b| b << [] }
      batch2 = Batch.new { |b| b << [:command_2] }
      (batch1==batch2).should be_false
    end
    specify do
      batch1 = Batch.new
      batch2 = Batch.new { |b| b << [:command_2] }
      (batch1==batch2).should be_false
    end
    specify do
      batch1 = Batch.new { |b| b << [:command_1] }
      batch2 = Batch.new { |b| b << [] }
      (batch1==batch2).should be_false
    end
  end

  describe "bind" do
    let(:command1) { [:create_node, {"id" => 7}] }
    let(:command2) { [:create_unique_node, {"id" => 8}] }
    let(:command3) { [:create_node, {"id" => 9}] }
    it "on unit with f should be equal f" do
      batch1, _, _ = create_batches(command1, command2, command3)

      Batch.unit().bind(batch1).should == batch1
    end

    it "with unit should be equal Batch" do
      batch1, _, _ = create_batches(command1, command2, command3)

      batch1.bind(Batch.unit()).should == batch1
    end

    it "chained should be equal to bind with inner binds" do
      batch1, batch2, batch3 = create_batches(command1, command2, command3)
      result1 = batch3.bind(batch1).bind(batch2)

      batch1, batch2, batch3 = create_batches(command1, command2, command3)
      f = ->() { batch1 }
      g = ->() { batch2 }
      result2 = batch3.bind(batch1.bind(batch2))

      result1.should == result2
    end

    describe "and submit" do
      it "should combine separate batches into one batch" do
        batch1 = Batch.new(db)
        ref11 = batch1 << [:create_node, {"id" => 1}]
        ref12 = batch1 << [:create_node, {"id" => 2}]
        batch1 << [:create_relationship, ref11, ref12, {}]

        batch2 = Batch.new(db)
        ref21 = batch2 << [:create_node, {"id" => 3}]
        ref22 = batch2 << [:create_node, {"id" => 4}]
        batch2 << [:create_relationship, ref21, ref22, {}]

        batch = batch2.bind(batch1)

        db.should_receive(:batch).with do |*commands|
          commands[0].should == [:create_node, {"id" => 3}]
          commands[1].should == [:create_node, {"id" => 4}]
          commands[2].should == [:create_relationship, "{0}", "{1}", {}]
          commands[3].should == [:create_node, {"id" => 1}]
          commands[4].should == [:create_node, {"id" => 2}]
          commands[5].should == [:create_relationship, "{3}", "{4}", {}]
        end.and_return([])

        batch.submit()
      end
    end
  end
  describe "find_reference" do
    it "should return reference when command is found" do
      ref1 = subject << [:create_node, {"id" => 7}]
      ref2 = subject << [:create_node, {"id" => 8}]
      subject << [:create_relationship, ref2, ref1, {}]

      result = subject.find_reference { |c| c[0] == :create_node && c[1]["id"] == 8 }
      result.should have(1).item
      result.should include(ref2)
    end

    it "should return empty when command is not found" do
      result = subject.find_reference { |c| c[0] == :create_node && c[1]["id"] == 8 }
      result.should be_empty
    end

    it "should return all reference when no predicate specified" do
      ref1 = subject << [:create_node, {"id" => 7}]
      ref2 = subject << [:create_node, {"id" => 8}]

      result = subject.find_reference()
      result.should have(2).item
    end
  end
  describe "<<" do
    it "should be the same as add when command is argument" do
      command = [:create_node]
      batch_used_with_add = Batch.new
      batch_used_with_add.add command

      subject << command

      subject.should == batch_used_with_add
    end
    it "should be the same as bind when command is Batch" do
      another_batch = Batch.new do |b|
        b << [:create_node]
      end
      subject << [:create_node]

      subject << another_batch

      db.should_receive(:batch) do |*commands|
        commands.should have(2).items
      end.and_return([])
      subject.submit()
    end
  end
  describe "add and submit" do
    it "should raise exception when added element doesn't respond to :each" do
      -> { subject.add(1) }.should raise_exception(StandardError)
    end

    it "should add command to be submitted later" do
      command = [:create_node]
      subject.add(command)

      db.should_receive(:batch).with(command).and_return([])

      subject.submit()
    end

    it "should resolve references to preceding commands" do
      jim = subject << [:create_node]
      john = subject << [:create_node]
      subject << [:create_relationship, john, jim]

      db.should_receive(:batch).with do |*commands|
        relationship_cmd = commands.last
        relationship_cmd[1].should == "{1}" # john was resolved to index where john was created
        relationship_cmd[2].should == "{0}" # jim was resolved to index where john was created
      end.and_return([])

      subject.submit()
    end

    context "when list 2 commands" do
      before do
        @john = subject.add [:create_node]
        @markus = subject.add [:create_node]
      end
      context "and another command is added" do
        let(:another_command) { [:create_relationship] }
        before do
          subject.add(another_command)
        end
        it "should contain 3 commands" do
          db.should_receive(:batch).with do |*commands|
            commands.should have(3).items
          end.and_return([])

          subject.submit()
        end
        it "should append command" do
          db.should_receive(:batch).with do |*commands|
            commands.last.should == another_command
          end.and_return([])

          subject.submit()
        end
      end
    end
  end
  describe "submit" do
    it "should raise exception when server returns error" do
      # this provokes a server error, because the second create_unique_node cannot be reference in create_relationship
      subject << [:create_unique_node, "test", "id", "1", {}]
      subject << [:create_unique_node, "test", "id", "2", {}]
      subject << [:create_relationship, "test", "{0}", "{1}", {}]

      ->() { subject.submit() }.should raise_error(StandardError)
    end
    it "should notify reference handler" do
      node_1_result = nil
      node_2_result = nil
      ref1 = subject << [:create_node, {"id" => 1}]
      ref2 = subject << [:create_node, {"id" => 2}]
      ref1.after_submit do |node|
        node_1_result = node
      end
      ref2.after_submit do |node|
        node_2_result = node
      end

      subject.submit()

      node_1_result.should_not be_nil
      node_2_result.should_not be_nil
      node_1_result["data"]["id"].should == 1
      node_2_result["data"]["id"].should == 2
    end

    it "should reset state of batch" do
      subject << [:create_node, {"id" => 1}]
      subject.submit()

      db.should_not_receive(:batch)
      result = subject.submit()
      result.should be_empty
    end

    context "one create_node added" do
      before { subject << [:create_node, {}] }
      it "should return created node" do
        result = subject.submit()
        result.should have(1).items
      end
      it "should create-node on Db" do
        result = subject.submit()

        node = result.first
        node_id = db.get_id(node)
        count = db.execute_query("start s=node(#{node_id}) return count(*)")
        count["data"][0][0].should == 1
      end
    end
  end
end