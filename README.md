## Introduction
Makes [neography-batches](https://github.com/maxdemarzi/neography/wiki/Batch "Neography Batch") better composable. By composing batches you can
* reduce the number of calls to the neo4j-server and there dramatically reduce network latency
* effectively implement transactions by aggregating the results of smaller calculations into one large transactional batch

Batches can be created at different locations in your source-code and ['neography-commands'](https://github.com/maxdemarzi/neography/wiki/Batch) are added to those batches.
Batches than can be aggregated to larger batches and submitted to the neo4j-server in one transaction.

Batches might be the foundation to more advanced concepts like [UnitOfWork](http://www.martinfowler.com/eaaCatalog/unitOfWork.html) or [Aggregates](http://en.wikipedia.org/wiki/Domain-driven_design)
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
Batches
### Creating a batch
A batch can be created by
``` ruby
batch = Neography::Composable::Batch.new
# add commands to the batch here
```
or
``` ruby
batch = Neography::Composable::Batch.new do |b|
    # add commands to the batch here
end
```
### Adding commands & submitting them
``` ruby
batch << [:create_node, {'name' => 'john'}]
batch << [:create_node, {'name' => 'lucy'}]
batch.submit()
```
### Joining & submitting a batch
``` ruby
super_batch = persons_batch << employee_batch << wages_batch
super_batch.submit()
```
### Referencing & submitting a batch
 ```
ibm = company_batch << [:create_node, {'name' => 'IBM'}]
john = persons_batch << [:create_node, {'name' => 'john'}]
lucy = persons_batch << [:create_node, {'name' => 'lucy'}]
employee_batch <<  [:create_relationship, 'employee', ibm, john]
employee_batch <<  [:create_relationship, 'employee', ibm, john]

super_batch = company_batch << persons_batch << employee_batch
super_batch.submit()
 ```
## Running tests
### Installing & starting neo4j
A few tests run against a neo4j-instance. This instance can be installed and run using following rake commands:
```sh
rake neo4j:install                           # Install Neo4j to the neo4j directory under your project
rake neo4j:start                             # Start Neo4j
rake neo4j:stop                              # Stop Neo4j
```
For a complete documentation see [neography's rake tasks](https://github.com/maxdemarzi/neography/wiki/Rake-tasks "Rake tasks")
### Tests
Tests can best be executed with:
```sh
rake spec
```
## License
This work is licensed under [GNU General Public License (v3 or later)](http://www.gnu.org/licenses/gpl-3.0.html)

### 3-party licenses
* Neography - MIT, see the LICENSE file http://github.com/maxdemarzi/neography/tree/master/LICENSE.
