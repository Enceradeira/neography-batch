## Introduction
Neography-Batch makes [neography-batches](https://github.com/maxdemarzi/neography/wiki/Batch "Neography Batch") better composable. By composing batches you can
* reduce the number of calls to the neo4j-server and therefore reducing network latency
* implement transactions by aggregating the results of smaller computations into one large transactional batch

```ruby
batch_1 = Neography::Composable::Batch.new
john = batch_1 << [:create_node, {'name' => 'john'}]

batch_2 = Neography::Composable::Batch.new
lucy = batch_2 << [:create_node, {'name' => 'lucy'}]

batch_3 = Neography::Composable::Batch.new
batch_3 << [:create_relationship, 'friend_of', john, lucy]

super_batch = batch_1 << batch_2 << batch_3
super_batch.submit()
```
Batches might be the foundation to more advanced concepts like [UnitOfWork](http://www.martinfowler.com/eaaCatalog/unitOfWork.html) or [Aggregates](http://en.wikipedia.org/wiki/Domain-driven_design).
## Installation
### Gemfile:
Add `neography-batch` to your Gemfile:
```ruby
gem 'neography-batch'
```
And run Bundler:
```sh
$ bundle install
```
### Manually:
Or install `neography-batch` manually:
```sh
$ gem install 'neography-batch'
```
And require the gem in your Ruby code:
```ruby
require 'neography-batch'
```
## Usage
### Creating a batch
A batch is be created by
```ruby
batch = Neography::Composable::Batch.new
# add commands to the batch here
```
or
```ruby
batch = Neography::Composable::Batch.new do |b|
    # add commands to the batch here
end
```
See also [read and write examples](https://github.com/Enceradeira/neography-batch/blob/master/spec/examples/read_and_write_examples_spec.rb).
### Adding commands & submitting
```ruby
batch << [:create_node, {'name' => 'john'}]
batch << [:create_node, {'name' => 'lucy'}]
batch.submit()
```
You can add everything that is supported by neography's-batch. See [here](https://github.com/maxdemarzi/neography/wiki/Batch) for details.
### Aggregating & submitting
```ruby
super_batch = persons_batch << employee_batch << wages_batch
super_batch.submit()
```
See also [reference and notification examples](https://github.com/Enceradeira/neography-batch/blob/master/spec/examples/references_and_notification_examples_spec.rb).
### Referencing & submitting
 ```ruby
ibm = company_batch << [:create_node, {'name' => 'IBM'}]
john = persons_batch << [:create_node, {'name' => 'john'}]
lucy = persons_batch << [:create_node, {'name' => 'lucy'}]
employee_batch <<  [:create_relationship, 'employee', ibm, john]
employee_batch <<  [:create_relationship, 'employee', ibm, lucy]

super_batch = company_batch << persons_batch << employee_batch
super_batch.submit()
 ```
See also [reference and notification examples](https://github.com/Enceradeira/neography-batch/blob/master/spec/examples/references_and_notification_examples_spec.rb).
## Running tests
### Installing & starting neo4j
A few tests run against a neo4j-instance. This instance can be installed and run using following rake commands:
```sh
rake neo4j:install                           # Install Neo4j to the neo4j directory under your project
rake neo4j:start                             # Start Neo4j
rake neo4j:stop                              # Stop Neo4j
```
For a complete documentation see [neography's rake tasks](https://github.com/maxdemarzi/neography/wiki/Rake-tasks "Rake tasks").
### Tests
Tests can best be executed with:
```sh
rake spec
```
## License
This work is licensed under [GNU General Public License (v3 or later)](http://www.gnu.org/licenses/gpl-3.0.html)

### 3-party licenses
* Neography - MIT, see the LICENSE file http://github.com/maxdemarzi/neography/tree/master/LICENSE.
