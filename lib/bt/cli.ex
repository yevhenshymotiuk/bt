defmodule Bt.CLI do
  use ExCLI.DSL, escript: true
  alias Bt.CLI.Config

  name "bt"
  description "Bluetooth CLI"
  long_description """
  Handling bluetooth devices from the shell
  """

  command :connect do
    aliases [:con]
    description "Connect device"
    long_description """
    Connect bluetooth device
    """

    argument :alias

    run context do
      aliases = Config.aliases()
      {_res, code} = System.cmd("bluetoothctl", ["connect", aliases[context.alias]])
      if code == 0 do
        IO.puts("Device was successfully connected")
      else
        IO.puts("Failed to connect")
      end
    end
  end

  command :disconnect do
    aliases [:dcon]
    description "Disconnect device"
    long_description """
    Disconnect bluetooth device
    """

    argument :alias

    run context do
      aliases = Config.aliases()
      {_res, code} = System.cmd("bluetoothctl", ["disconnect", aliases[context.alias]])
      if code == 0 do
        IO.puts("Device was successfully disconnected")
      else
        IO.puts("Failed to disconnect")
      end
    end
  end

  def response_list_to_map(list) do
    list
      |> String.trim()
      |> String.split("\n")
      |> Enum.reduce(
        %{},
        fn x, acc ->
          [_, mac, name] = String.split(x, " ", parts: 3)
          Map.put(acc, mac, name)
        end
      )
  end

  command :devices do
    aliases [:devs]
    description "List devices"
    long_description """
    List bluetooth devices
    """

    run _context do
      {res, _code} = System.cmd("bluetoothctl", ["devices"])
      res
      |> response_list_to_map()
      |> Enum.map(fn {_mac, name} -> name end)
      |> Enum.join("\n")
      |> IO.puts()
    end
  end

  command :adapters do
    aliases [:controllers]
    description "List adapters"
    long_description """
    List bluetooth adapters
    """

    run _context do
      {res, _code} = System.cmd("bluetoothctl", ["list"])
      res
      |> response_list_to_map()
      |> Enum.map(fn {_mac, name} -> name end)
      |> Enum.join("\n")
      |> IO.puts()
    end
  end

  command :alias do
    description "List aliases"
    long_description """
    List aliases of devices
    """

    argument :action

    run context do
      cond do
        context.action == "ls" ->
          {res, _code} = System.cmd("bluetoothctl", ["devices"])
          devices = response_list_to_map(res)
          aliases = Config.aliases()

          aliases
          |> Enum.map(
            fn {name, mac} ->
              "#{name} -> #{devices[mac]}"
            end
          )
          |> Enum.join("\n")
          |> IO.puts()

        context.action == "add" ->
          # List devices
          {res, _code} = System.cmd("bluetoothctl", ["devices"])
          devices = response_list_to_map(res)

          devices
          |> Enum.with_index()
          |> Enum.map(fn {{_mac, name}, i} -> "#{i+1}. #{name}" end)
          |> Enum.join("\n")
          |> IO.puts()

          # Choose device
          device_id =
            "Select device: "
            |> IO.gets()
            |> String.trim()
            |> String.to_integer()
            |> Kernel.-(1)

          {device_mac, _device_name} = Enum.at(devices, device_id)

          # Choose alias name
          alias_name =
            "Enter alias: "
            |> IO.gets()
            |> String.trim()

          # Add alias
          Config.aliases()
          |> Enum.map(
            fn {name, mac} ->
              if mac == device_mac do
                {alias_name, mac}
              else
                {name, mac}
              end
            end
          )
          |> Enum.into(%{})
          |> Config.write_aliases()
      end
    end
  end
end
