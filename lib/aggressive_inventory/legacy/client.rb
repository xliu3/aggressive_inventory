require 'httparty'
# oh what a mess
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/numeric/time'

module AggressiveInventory
  module Legacy
    class Client
      include AggressiveInventory::Util

      attr_reader :base_uri, :auth_token

      def initialize()
        @base_uri = AggressiveInventory.base_uri
        @auth_token = AggressiveInventory.auth_token
        @get_headers = { 'Authorization' => "Token #{@auth_token}" }
        @post_headers = @get_headers.merge('Content-Type' => 'application/json')
      end

      def item_types
        response = HTTParty.get(@base_uri + 'item_types/', headers: @get_headers)
        handle_item_type_errors(response)
        JSON.parse(response.body)
      end

      def create_item_type(name, allowed_keys = [])
        response = HTTParty.post(@base_uri + 'item_types/',
                                 body: { 'name' => name, 'allowed_keys' => allowed_keys }.to_json,
                                 headers: @post_headers)
        handle_item_type_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def item_type(uuid)
        raise ArgumentError unless uuid.present?
        response = HTTParty.get(@base_uri + "item_types/#{uuid}", headers: @get_headers)
        handle_item_type_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def update_item_type(uuid, params)
        raise ArgumentError if params.empty?
        response = HTTParty.put(@base_uri + "item_types/#{uuid}", body: params.to_json, headers: @post_headers)
        handle_item_type_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def delete_item_type(uuid)
        response = HTTParty.delete(@base_uri + "item_types/#{uuid}", headers: @get_headers)
        handle_item_type_errors(response)
        # returns nothing on success
      end

      def create_item(item_type_uuid, name, reservable, metadata = {})
        response = HTTParty.post(@base_uri + 'items/',
                                 body: { 'name' => name, 'item_type_uuid' => item_type_uuid, 'reservable' => reservable, 'data' => metadata }.to_json,
                                 headers: @post_headers)
        handle_item_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def item(uuid)
        response = HTTParty.get(@base_uri + "items/#{uuid}", headers: @get_headers)
        handle_item_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def items_by_type(item_type_uuid)
        item_type(item_type_uuid)['items']
      end

      def update_item(uuid, params = {})
        raise ArgumentError if params.empty?
        response = HTTParty.put(@base_uri + "items/#{uuid}", body: params.to_json, headers: @post_headers)
        handle_item_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def delete_item(uuid)
        response = HTTParty.delete(@base_uri + "items/#{uuid}", headers: @get_headers)
        handle_item_errors(response)
        # returns nothing on success
      end

      def create_reservation(item_type, start_time, end_time)
        response = HTTParty.post(@base_uri + 'reservations/',
                                 body: { 'item_type' => item_type, 'start_time' => start_time.iso8601, 'end_time' => end_time.iso8601 }.to_json,
                                 headers: @post_headers)
        handle_reservation_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def reservation(uuid)
        raise ArgumentError unless uuid.present?
        response = HTTParty.get(@base_uri + "reservations/#{uuid}", headers: @get_headers)
        handle_reservation_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def reservations(start_time, end_time, item_type)
        body = { 'start_time' => start_time.iso8601, 'end_time' => end_time.iso8601, 'item_type' => item_type }
        response = HTTParty.get(@base_uri + 'reservations/', body: body.to_json, headers: @post_headers)
        handle_reservation_errors(response)
        JSON.parse(response.body)
      end

      # this sort of request only updates the reservations start and end time
      # (this is a constraint by the api)
      def update_reservation(uuid, params = {})
        raise ArgumentError if params.empty?
        params = params.with_indifferent_access
        params[:start_time] = params[:start_time].iso8601 if params[:start_time]
        params[:end_time] = params[:end_time].iso8601 if params[:end_time]
        response = HTTParty.put(@base_uri + "reservations/#{uuid}", body: { reservation: params }.to_json, headers: @post_headers)
        handle_reservation_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def update_reservation_start_time(uuid, start_time)
        update_reservation(uuid, start_time: start_time)
      end

      def update_reservation_end_time(uuid, end_time)
        update_reservation(uuid, end_time: end_time)
      end

      def update_reservation_data(uuid, params = {})
        raise ArgumentError if params.empty?
        response = HTTParty.post(@base_uri + "reservations/#{uuid}/update_item", body: params.to_json, headers: @post_headers)
        handle_reservation_errors(response)
        # returns nothing on success
      end

      def delete_reservation(uuid)
        response = HTTParty.delete(@base_uri + "reservations/#{uuid}", headers: @get_headers)
        handle_reservation_errors(response)
        # returns nothing on success
      end

#------------------------------>damage
      def create_damage(damage_type_name, rental_uuid, repair_uuid)
        response = HTTParty.post(@base_uri + "damages/",
                                 body: { 'damage_type' => damage_type_name,
                                         'rental_uuid' => rental_uuid,
                                         'repair_uuid' => repair_uuid },
                                 headers: @post_headers).to_json
        handle_damage_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def damage(uuid)
        response = HTTParty.get(@base_uri + "damages/#{uuid}", headers: @get_headers)
        handle_reservation_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def damages(item)
        body = { 'item' => item }
        response = HTTParty.get(@base_uri + "damages/", body: body.to_json, headers: @get_headers)
        handle_reservation_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def delete_damage(uuid)
        response = HTTParty.delete(@base_uri + "damages/#{uuid}", headers: @get_headers)
        handle_reservation_errors
      end

      def create_damage_type(name)
        response = HTTParty.post(@base_uri + "damage_types/",
                                 body: { 'name' => name },
                                 headers: @post_headers).to_json
        handle_damage_type_errors(response)
        JSON.parse(response.body).with_indifferent_access
      end

      def damage_types
        response = HTTParty.get(@base_uri + "damage_types/", headers: @get_headers)
        handle_damage_type_errors
        JSON.parse(response.body)
      end

      def delete_damage_type(uuid)
        response = HTTParty.delete(@base_uri + "damage_types/#{uuid}", headers: @get_headers)
        handle_damage_type_errors
      end

      def update_damage_type(uuid, params = {})
        raise ArgumentError if params.empty?
        response = HTTParty.put(@base_uri + "damage_types/#{uuid}", body: params.to_json, heasers: @put_headers)
        handle_damage_type_errors
      end

      def damage_type(uuid)
        response = HTTParty.get(@base_uri + "damage_types/#{uuid}", heaser: @get_headers)
        handles_damage_type_errors
        JSON.parse(response.body).with_indifferent_access
      end
#-------------------------->

      def handle_item_type_errors(response)
        raise AuthError, response.body if response.code == 401
        raise ItemTypeError, response.body if response.code == 422
        raise ItemTypeNotFound, response.body if response.code == 404
        raise InventoryError, response.body if response.code != 200 # handles stuff like a 500
      end

      def handle_item_errors(response)
        raise AuthError, response.body if response.code == 401
        raise ItemError, response.body if response.code == 422
        raise ItemNotFound, response.body if response.code == 404
        raise InventoryError, response.body if response.code != 200
      end

      def handle_reservation_errors(response)
        raise AuthError, response.body if response.code == 401
        raise ReservationError, response.body if response.code == 422
        raise ReservationNotFound, response.body if response.code == 404
        raise InventoryError, response.body if response.code != 200
      end

      def handle_damage_errors(response)
        raise AuthError, response.body if response.code == 401
        raise DamageError, response.body if response.code == 422
        raise DamageNotFound, response.body if response.code == 404
        raise InventoryError, response.body if response.code != 200
      end

      def handle_damage_type_errors(response)
        raise AuthError, response.body if response.code == 401
        raise DamageTypeError, response.body if response.code == 422
        raise DamageTypeNotFound, response.body if response.code == 404
        raise IventoryError, response.body if response.code != 200
      end
    end
  end
end
