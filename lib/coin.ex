defmodule Coin do
  defstruct [:weight, :name]

  def createQuarter() do
    %Coin{weight: 5.670, name: :quarter}
  end

  def createDime() do
    %Coin{weight: 2.268, name: :dime}
  end

  def createNickel() do
    %Coin{weight: 5.0, name: :nickel}
  end
end
