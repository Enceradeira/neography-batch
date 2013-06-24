require 'spec_helper'

module Neography
  module Composable
    describe BatchReference do
      describe '==' do
        context 'different command-instances' do
          let(:command1) { [:create, {"id" => 1}] }
          let(:command2) { [:create, {"id" => 1}] }
          let(:ref1) { BatchReference.new(command1) }
          let(:ref2) { BatchReference.new(command2) }

          it 'is not equal' do
            expect(ref1).not_to eq(ref2)
          end
        end
        context 'same command-instances' do
          let(:command) { [:create, {"id" => 1}] }
          let(:ref1) { BatchReference.new(command) }
          let(:ref2) { BatchReference.new(command) }

          it 'is equal' do
            expect(ref1).to eq(ref2)
          end
          context 'same after_submit block' do
            let(:block) { Proc.new { | |} }
            before do
              ref1.after_submit(&block)
              ref2.after_submit(&block)
            end

            it 'is equal' do
              expect(ref1).to eq(ref2)
            end
          end
          context 'different after_submit block' do
            let(:block1) { Proc.new { | |} }
            let(:block2) { Proc.new { | |} }
            before do
              ref1.after_submit(&block1)
              ref2.after_submit(&block2)
            end

            it 'is equal' do
              expect(ref1).not_to eq(ref2)
            end
          end
        end
      end
    end
  end
end