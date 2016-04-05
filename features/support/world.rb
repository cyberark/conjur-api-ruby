module ApiWorld

  def namespace
    @namespace ||= $conjur.create_variable('text/plain', 'id').id.tap {|ns| puts "namespace: #{ns}"}
  end

end

World ApiWorld
