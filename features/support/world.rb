module ApiWorld

  def api
    @api ||= Conjur::Authn.connect(nil, :noask => true)
  end

  def namespace
    @namespace ||= api.create_variable('text/plain', 'id').id.tap {|ns| puts "namespace: #{ns}"}
  end

end

World ApiWorld
