/* I don't really know a good way to distribute CouchDB views */

{"_id":"_design/categories","_rev":"9-072b040a9fa4c4ab3874e496cccdacf7","language":"javascript","views":{"categories":{"map":"function(doc) {\n  emit(null, 1);\n  emit(doc.category, 1);\n  if (doc.subcategory) {\n    emit([doc.category, doc.subcategory], 1);\n  }\n}","reduce":"function(key, values) {\n  return sum(values);\n}"},"by_category":{"map":"function(doc) {\n  emit(null, doc.name);\n  emit(doc.category, doc.name);\n  if(doc.subcategory) {\n    emit([doc.category, doc.subcategory], doc.name);\n  }\n}"}}}

{"_id":"_design/fields","_rev":"1-d25b4f547b144a8a65d896c8d11d9e96","language":"javascript","views":{"field_count":{"map":"function(doc) {\n  Object.keys(doc).map(function(key) {\n    if (key[0] != '_') {\n      emit(key, 1);\n    }\n  })\n}","reduce":"function(key, values) {\n  return sum(values);\n}"}}}
