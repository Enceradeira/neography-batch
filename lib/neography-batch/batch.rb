class Batch
  private
  def initialize(graph_db = Neography::Rest.new, commands = [])
    @commands = commands
    @db = graph_db
    yield(self) if block_given?

  end

  def self.get_resolved_commands(commands)
    result = []
    reference_and_index = {}

    # write each command_or_batch and remember index of command_or_batch
    commands.each do |command|
      index = result.length
      reference_and_index[command[:reference]] = index
      result << command[:cmd]
    end

    # replace references contained in the commands with the effective index in the batch
    result.each do |command|
      command.each_with_index do |element, index|
        if reference_and_index.has_key?(element)
          command[index] = "{#{reference_and_index[element]}}"
        end
      end
    end
    result
  end

  protected
  def commands
    @commands
  end

  public
  def self.unit
    Batch.new
  end

  def add(command_or_batch)
    if command_or_batch.class == Batch
      bind(command_or_batch)
    else
      unless command_or_batch.respond_to?(:each)
        raise StandardError, "command_or_batch must respond to :each"
      end

      reference = BatchReference.new(command_or_batch)
      @commands << {:cmd => command_or_batch, :reference => reference}
      reference
    end
  end

  def find_reference
    @commands.select { |c| !block_given? || yield(c[:cmd]) }.map { |c| c[:reference] }
  end

  alias :<< :add

  def submit
    return [] if @commands.empty?
    command_list = Batch.get_resolved_commands(@commands)
    result = @db.batch(*command_list)
    if result.nil?
      raise StandardError, "batch returned no result (nil)"
    end
    batch_errors = result.select { |r| r["status"] >= 400 }
    if batch_errors.count > 0
      raise StandardError, "batch returned one or more errors: #{batch_errors.map { |e| e["message"] }.join("|")}"
    end
    results = result.map { |r| r["body"] }
    @commands.each_with_index { |c, i| c[:reference].notify_after_submit(results[i]) }
    @commands.clear()
    results
  end

  def bind(batch)
    Batch.new(@db, @commands.concat(batch.commands))
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    if other.class != self.class
      false
    else
      commands.length == other.commands.length &&
          commands.zip(other.commands).all? { |z| z[0] == z[1] }
    end
  end
end