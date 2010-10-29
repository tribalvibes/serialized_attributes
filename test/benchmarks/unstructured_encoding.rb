# assert ClassWithSerializedAttributes === r
# This tests the 'skip_encoding' option
# We just want to serialize unstructured data directly to/from the JSON backend
# See also lighthouse 2182

def run_bm(r)
  schema = r.class.send("data_schema")
  data_field = schema.instance_variable_get(:@field)
  data = r.send(data_field)
  schema.instance_variable_set(:@skip_encoding, false ) 
  s = r.send(data_field).to_s.size
  n = 10_000_000 / s
  puts "#{n} iterations data.size #{s}"
    Benchmark.bm do |bm|
     schema.instance_variable_set(:@skip_encoding, false ) 
     bm.report('encoded encode:') do
       n.times{ 
        r.reset_serialized_data; r.score = "foo\u00a9"
        schema.encode(data)
         }
     end
     bm.report('encoded decode:') do
       n.times{ 
      r.reset_serialized_data; 
      r.send(data_field)
       raise " decoded!!" if DateTime === r.dateRun
      }
     end
     schema.instance_variable_set(:@skip_encoding, true ) 
     data = r.send(data_field)
     bm.report('unencoded encode:') do
       n.times{ 
        r.reset_serialized_data; r.score = "foo\u00a9"
        schema.encode(data)
         }
     end
     bm.report('unencoded decode:') do
       n.times{ 
        r.reset_serialized_data; 
        r.send(data_field)
        raise "didn't decode" unless DateTime === r.dateRun
      }
     end
   end
end
 
ruby-1.9.1-p378 >   run_bm(r)
22 iterations data.size 438900
      user     system      total        real
encoded encode:  7.960000   0.030000   7.990000 (  7.983606)
encoded decode:  5.320000   0.040000   5.360000 (  5.367752)
unencoded encode:  2.780000   0.020000   2.800000 (  2.789770)
unencoded decode:  2.460000   0.020000   2.480000 (  2.478758)
 => true 
