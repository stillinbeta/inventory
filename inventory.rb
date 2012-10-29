require 'sinatra/base'
require 'couchrest'
require 'json'
require 'haml'

COUCH_URL = 'http://localhost:5984/inventory/'

class Inventory < Sinatra::Base
  set :public_folder, File.dirname(__FILE__) + '/static'

  def initialize
    super()
    @db = CouchRest.database(COUCH_URL)
  end

  def get_categories
    categories = @db.view('categories/categories', :group => true)['rows']

    default = Hash.new do |hash, key|
     hash[key] = {:count => 0, :subcategories => Hash.new(0)}
    end
    categories.reduce(default) do |memo, item|  
      key, value = item['key'], item['value']
      if key.is_a? Array
        memo[key[0].to_sym][:subcategories][key[1].to_sym] += value
      elsif key.is_a? String
        memo[key.to_sym][:count] += value
      elsif key == nil
        memo[nil] = value 
      end
      memo
    end
  end

  def by_category(query)
    rows = @db.view('categories/by_category', {'key' => query})['rows']
    ## TODO - this will be untenable with large databases
    ## Fortunately I don't own very much
    rows.sort do |a,b|
      a['value'] <=> b['value']
    end
  end

  def get_field_count
    rows = @db.view('fields/field_count',
                    {'reduce' => true, 'group' => true})['rows']
    rows.sort do |a, b|
      # Descending order
      b['value'] <=> a['value']
    end
  end
  
  helpers do
    def capitolise(str)
      words = str.split('_').each do |str|
        str[0] = str[0].upcase 
      end
      words.join ' '
    end
   
    def category_loc(doc)
      str = "/#{ doc['category'] }/"
      if doc.has_key? 'subcategory'
        str += "#{ doc['subcategory']}/"
      end
      str
    end
    def category_link(category, count)
      "<a href='/#{ category }'>#{ category } (#{ count })</a>"
    end
    def subcategory_link(category, subcategory, count)
      "<a href='/#{ category }/#{ subcategory }/'>" + 
        "#{ subcategory } (#{ count })</a>"
    end
    def item_link(item)
      "<a href='/item/#{ item['id'] }'>#{ item['value'] }</a>"
    end
    def selected(actual, expected)
      if actual.to_s == expected.to_s
        'selected'
      else
        nil 
      end
    end

    def my_template(title, category=nil, subcategory=nil, &block)
      haml :base, :locals => {:title => title,
                              :categories => get_categories,
                              :selected_cat => category,
                              :selected_subcat => subcategory,
                              :block => block}
    end
  end

  def edit_item(item=nil)
    if not item
      item = Hash.new ''
    end
    field_array = get_field_count.map do |obj|
      obj['key']
    end
    categories = get_categories
    category_array = categories.reduce(Hash.new) do |memo, (category, val)|
      if category # Ignore nil
        memo[category] = val[:subcategories].keys
      end
      memo
    end

    my_template('add an item') do
      haml :add, :locals => {:category_list => category_array.to_json,
                             :field_list => field_array.to_json,
                             :item => item}
    end
  end

  get '/' do
    my_template('home') do
      haml :list, :locals => {:items => by_category(nil)}
    end
  end

  get '/add' do
    edit_item
  end

  post '/add' do
    result = @db.save_doc(params)
    if result['ok']
      redirect '/item/' + result['id']
    else
      my_template("Save failed!") do
        "Save failed, sorry!"
      end
    end
  end

  get %r{/item/([a-f0-9]+)/edit/?$} do |item|
    begin
      document = @db.get(item)
    rescue RestClient::ResourceNotFound
      raise Sinatra::NotFound
    end
    edit_item document
  end

  get %r{/item/([a-f0-9]+)/?$} do |item|
    begin
      document = @db.get(item)
    rescue RestClient::ResourceNotFound
      raise Sinatra::NotFound
    end
    category = document['category']
    subcategory = document['subcategory'] if document.has_key? 'subcategory'
    my_template(document['name'], category, subcategory) do
      haml :item, :locals => {:item => document}
    end
  end

  delete %r{/item/([a-f0-9]+)/?$} do |item|
    @db.delete_doc({'_id' => item, '_rev' => params["rev"]})
    'Deleted'
  end

  get %r{/([a-z]+)/([a-z]+)/?$} do |category, subcategory|
    my_template(subcategory, category, subcategory) do
      haml :list, :locals => {
          :items => by_category([category, subcategory])
      }
    end
  end

  get %r{/([a-z]+)/?$} do |category|
    my_template(category, category) do
      haml :list, :locals => {:items => by_category(category)}
    end
  end

  run! if $0 == app_file
end
