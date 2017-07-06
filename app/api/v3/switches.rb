module V3
  class Switches < Grape::API
    helpers V3::Helpers

    version 'v3'
    format :json

    resource :switches do
      before do
        api_enabled!
        authenticate!
        set_papertrail
        @owner = get_owner
      end

      route_param :fqdn, type: String, requirements: { fqdn: /[a-zA-Z0-9.]+/ } do
        desc 'Get a switch by fqdn', success: Switch::Entity
        get do
          can_read!
          s = Switch.find_by_fqdn params[:fqdn]
          error!('Not found', 404) unless s

          present s
        end

        desc 'Update a switch', success: Switch::Entity
        params do
          requires :fqdn, type: String
        end
        put do
          can_write!
          s = Switch.find_by_fqdn params[:fqdn]
          error!('Not found', 404) unless s
          
          p = declared(params).to_h
          s.update_attributes(p)
          present s
        end

        desc 'Delete a switch'
        delete do
          can_write!
          s = Switch.find_by_fqdn params[:fqdn]
          error!('Not found', 404) unless s
          s.destroy
        end

        resource :ports do
          route_param :number, type: Integer, requirements: { number: /[0-9]+/ } do
            desc 'Get a switch port', success: SwitchPort::Entity
            get do
              can_read!
              s = Switch.find_by_fqdn params[:fqdn]
              error!('Not found', 404) unless s

              p = SwitchPort.find_by number: params[:number], switch_id: s.id
              error!('Not found', 404) unless p
              present p
            end

            desc 'Update a switch port', success: SwitchPort::Entity
            params do
              requires :number, type: Integer, documentation: { type: "Integer", desc: "Port number" }
              requires :nic, type: String, documentation: { type: "String", desc: "Nic name" }
              requires :machine, type: String, documentation: { type: "String", desc: "Machine nic belongs to" }
            end
            put do
              can_write!
              s = Switch.find_by_fqdn params[:fqdn]
              error!('Not found', 404) unless s

              m = Machine.find_by_fqdn params[:machine]
              error!('Machine not found', 404) unless m

              n = Nic.find_by(name: params[:nic], machine: m.id)
              error!('Nic not found', 404) unless n

              port = SwitchPort.find_by number: params[:number], switch_id: s.id
              error!('Not found', 404) unless port

              p = {'switch_id' => s.id, 'nic_id' => n.id, 'number' => params[:number]}
              port.update_attributes!(p)

              present port
              status 201
            end

            desc 'Delete a switch port'
            delete do
              can_write!
              port = SwitchPort.find_by_id params[:number]
              error!('Not found', 404) unless port

              port.destroy
            end
          end

          desc 'Return a list of switch ports', is_array: true, success: SwitchPort::Entity
          get do
            can_read!
            s = Switch.find_by_fqdn params[:fqdn]
            error!('Not found', 404) unless s

            present SwitchPort.where(switch_id: s.id)
          end

          desc 'Add a new switch port', success: SwitchPort::Entity
          params do
            requires :number, type: Integer, documentation: { type: "Integer", desc: "Port number" }
            requires :nic, type: String, documentation: { type: "String", desc: "Nic name" }
            requires :machine, type: String, documentation: { type: "String", desc: "Machine nic belongs to" }
          end
          post do
            can_write!
            s = Switch.find_by_fqdn params[:fqdn]
            error!('Switch not found', 404) unless s

            m = Machine.find_by_fqdn params[:machine]
            error!('Machine not found', 404) unless m

            n = Nic.find_by(name: params[:nic], machine: m.id)
            error!('Nic not found', 404) unless n

            p = {'switch_id' => s.id, 'nic_id' => n.id, 'number' => params[:number]}

            port = SwitchPort.create(p)
            present port
          end
        end
      end

      desc 'Return a list of switches, possibly filtered', is_array: true, success: Switch::Entity
      get do
        can_read!

        query = Switch.all
        params.delete('idb_api_token')
        params.each do |key, value|
          keysym = key.to_sym
          query = query.merge(Switch.where(Switch.arel_table[keysym].eq(value)))
        end

        begin
          query.any?
        rescue ActiveRecord::StatementInvalid
          error!('Bad Request', 400)
        end

        present query
      end

      desc 'Create a new switch', success: Switch::Entity
      params do
        requires :fqdn, type: String
      end
      post do
        can_write!
        if Switch.find_by_fqdn params['fqdn']
          error!('Entry with this FQDN already exists.', 409)
        end
        p = declared(params).to_h

        m = Switch.new(p)
        m.owner = @owner
        m.save!

        present m
      end
    end
  end
end
