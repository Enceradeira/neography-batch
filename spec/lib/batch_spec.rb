require 'spec_helper'


module Neography
  module Composable
    describe Batch do
      let(:neo) { Neography::Rest.new }
      describe 'new' do
        context 'without block' do
          let(:batch) { Batch.new(neo) }

          it 'is equal unit' do
            expect(batch).to eq(Batch.unit())
          end
        end
        context 'with block containing one command' do
          let(:command) { [:command] }
          let(:batch) do
            Batch.new(neo) do |b|
              b << command
            end

            it 'is equal batch with one command added' do
              other_batch = Batch.new(neo)
              other_batch << command
              expect(batch).to eq(other_batch)
            end
          end
        end
      end
      describe '==' do
        context 'two empty batches' do
          let(:empty_batch) { Batch.new(neo) }
          let(:another_empty_batch) { Batch.new(neo) }

          it 'are equal' do
            expect(empty_batch).to eq(another_empty_batch)
          end
        end
        context 'batch and something else' do
          let(:batch) { Batch.new(neo) }
          let(:something_different) { [] }

          it 'are different' do
            expect(batch).not_to eq(something_different)
          end
        end
        context 'two batches with same command instances' do
          let(:command) { [:command] }
          let(:batch) { Batch.new(neo) { |b| b << command } }
          let(:another_batch) { Batch.new(neo) { |b| b << command } }

          it 'are equal' do
            expect(batch).to eq(another_batch)
          end
        end
        context 'two batches with different command instances' do
          let(:batch) { Batch.new(neo) { |b| b << [:command] } }
          let(:another_batch) { Batch.new(neo) { |b| b << [:command] } }

          it 'are different' do
            expect(batch).not_to eq(another_batch)
          end
        end
        context 'two batches and one of which has empty command' do
          let(:empty_cmd_batch) { Batch.new(neo) { |b| b << [] } }
          let(:batch) { Batch.new(neo) { |b| b << [:command] } }

          it 'are different' do
            expect(batch).not_to eq(empty_cmd_batch)
            expect(empty_cmd_batch).not_to eq(batch)
          end
        end
        context 'two batches and one of which is empty command' do
          let(:empty_batch) { Batch.new(neo) }
          let(:batch) { Batch.new(neo) { |b| b << [:command] } }

          it 'are different' do
            expect(batch).not_to eq(empty_batch)
            expect(empty_batch).not_to eq(batch)
          end
        end
      end

      describe 'bind' do
        context "batch"
        let(:command) { [[:create_node, {'id' => 7}]] }
        let(:batch) { Batch.new(neo) { |b| b << command } }
        context 'with unit' do
          let(:unit) { Batch.unit() }

          it 'equal batch' do
            expect(unit.bind(batch)).to eq(batch)
          end
        end
        context 'unit' do
          let(:unit) { Batch.unit() }
          context 'with batch' do
            let(:command) { [[:create_node, {'id' => 7}]] }
            let(:batch) { Batch.new(neo) { |b| b << command } }
          end

          it 'equal batch' do
            expect(unit.bind(batch)).to eq(batch)
          end
        end
        context 'three batches' do
          let(:command1) { [:create_node, {'id' => 7}] }
          let(:command2) { [:create_unique_node, {'id' => 8}] }
          let(:command3) { [:create_node, {'id' => 9}] }
          let(:batch1) { Batch.new(neo) { |b| b << command1 } }
          let(:batch2) { Batch.new(neo) { |b| b << command2 } }
          let(:batch3) { Batch.new(neo) { |b| b << command3 } }

          context 'once chained and once inner bound' do
            let(:chained_batch) { batch3.bind(batch1).bind(batch2) }
            let(:inner_bound_batch) { batch3.bind(batch1.bind(batch2)) }

            it "are equal" do
              expect(chained_batch).to eq(inner_bound_batch)
            end
          end
        end
        context 'two batches containing commands that reference into other batch' do
          let(:two_batches) do
            batch1 = Batch.new(neo)
            batch2 = Batch.new(neo)

            ref11 = batch1 << [:create_node, {'id' => 1}]
            ref12 = batch1 << [:create_node, {'id' => 2}]
            ref21 = batch2 << [:create_node, {'id' => 3}]
            ref22 = batch2 << [:create_node, {'id' => 4}]

            batch1 << [:create_relationship, ref11, ref22, {}]
            batch2 << [:create_relationship, ref21, ref22, {}]
            [batch1, batch2]
          end
          let(:super_batch) { two_batches[1].bind(two_batches[0]) }

          describe "and submit" do

            it "updates references" do
              neo.should_receive(:batch).with do |*commands|
                commands[0].should == [:create_node, {'id' => 3}]
                commands[1].should == [:create_node, {'id' => 4}]
                commands[2].should == [:create_relationship, "{0}", "{1}", {}]
                commands[3].should == [:create_node, {'id' => 1}]
                commands[4].should == [:create_node, {'id' => 2}]
                commands[5].should == [:create_relationship, "{3}", "{1}", {}]
              end.and_return([])

              super_batch.submit()
            end
          end
        end
      end
      describe 'find_reference' do
        let(:batch) { Batch.new(neo) }
        context 'with three commands' do
          let(:command1) { [:create_node, {'id' => 7}] }
          let(:command2) { [:create_node, {'id' => 8}] }
          let(:command3) { [:create_relationship, ref1, ref2, {}] }
          let!(:ref1) { batch << command1 }
          let!(:ref2) { batch << command2 }
          let!(:ref3) { batch << command3 }

          context 'when predicate matches for one reference' do
            let!(:result) { batch.find_reference { |c| c == command2 } }

            it 'returns one reference' do
              expect(result).to have(1).item
            end
            it 'returns matching reference' do
              expect(result).to include(ref2)
            end
          end

          context 'when predicate does not match' do
            let!(:result) { batch.find_reference { |c| false } }
            it 'returns no reference' do
              expect(result).to be_empty
            end
          end

          context 'when no predicate specified' do
            let!(:result) { batch.find_reference }
            it 'returns all references' do
              expect(result).to have(3).items
            end
          end
        end
      end
      describe '<<' do
        context 'with command' do
          let(:command) { [:create_node] }
          it 'is like add command' do
            batch_with_add = Batch.new(neo)
            batch = Batch.new(neo)

            batch_with_add.add(command)
            batch << command

            expect(batch).to eq(batch_with_add)
          end
        end
        context 'with batch' do
          let(:another_batch) { Batch.new(neo) { |b| b << [:create_node] } }
          it 'is like bind batch' do
            batch_with_bind = Batch.new(neo)
            batch = Batch.new(neo)

            batch_with_bind.bind(another_batch)
            batch << another_batch

            expect(batch).to eq(batch_with_bind)
          end
        end
      end

      describe 'add' do
        context "subclassed batch class" do
          class SubclassedBatch < Batch
          end
          let(:command1) { [:create_node] }
          let(:command2) { [:create_relationship] }
          let(:batch) { Batch.new { |b| b << command1 } }
          let(:subclassed_batch) { SubclassedBatch.new(neo) { |b| b << command2 } }

          it "combines batches" do
            expected_batch = Batch.new(neo) do |b|
              b << command1
              b << command2
            end

            result = batch.add(subclassed_batch)
            expect(result).to eq(expected_batch)
          end
        end
        context 'element that does not respond to :each' do
          it 'raises StandardError' do
            -> { subject.add(1) }.should raise_exception(StandardError)
          end
        end
      end

      describe 'submit' do
        let(:batch) { Batch.new(neo) }
        context 'with one added command' do
          let(:command) { [:create_node, {'id' => 1}] }
          before { batch.add(command) }

          it 'calls neography-batch with added command' do
            neo.should_receive(:batch).with(command).and_return([])

            batch.submit()
          end
          context 'and second submit' do
            before { batch.submit() }

            it 'does nothing the second time' do
              neo.should_not_receive(:batch)

              batch.submit()
            end
          end
        end
        context 'with a relation between to commands' do
          let!(:ref_1) { batch << [:create_node] }
          let!(:ref_2) { batch << [:create_node] }
          let!(:relation) { batch << [:create_relationship, ref_2, ref_1] }

          it 'resolves references to preceding commands' do
            neo.should_receive(:batch).with do |*commands|
              relationship_cmd = commands.select { |r| r[0]==:create_relationship }.first
              relationship_cmd[1].should == "{1}"
              expect(relationship_cmd[1]).to eq("{1}")
              expect(relationship_cmd[2]).to eq("{0}")
            end.and_return([])

            batch.submit()
          end
        end
        context 'with commands that trigger a server error' do
          before do
            # this provokes a server error, because the second create_unique_node cannot be reference in create_relationship
            batch << [:create_unique_node, "test", "id", "1", {}]
            batch << [:create_unique_node, "test", "id", "2", {}]
            batch << [:create_relationship, "test", "{0}", "{1}", {}]
          end
          it 'raises StandardError' do
            ->() { batch.submit() }.should raise_error(StandardError)
          end
        end
        context 'with two after_submit handlers' do
          let(:command1) { [:create_node, {'id' => 1}] }
          let!(:reference1) { batch << command1 }
          let(:command2) { [:create_node, {'id' => 2}] }
          let!(:reference2) { batch << command2 }
          it 'notifies reference1' do
            node = nil
            reference1.after_submit do |n|
              node = n
            end

            batch.submit()

            expect(node).not_to be_nil
            expect(node['data']['id']).to be(command1[1]['id'])
          end
          it 'notifies reference2' do
            node = nil
            reference2.after_submit do |n|
              node = n
            end

            batch.submit()

            expect(node).not_to be_nil
            expect(node['data']['id']).to be(command2[1]['id'])
          end
        end
      end
    end
  end
end
