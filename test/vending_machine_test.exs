defmodule VendingMachine.Test do
  use ExUnit.Case
  import Utilities
  doctest VendingMachine

  @invalid %Coin{weight: 2.5}
  @nickel Coin.createNickel()
  @dime Coin.createDime()
  @quarter Coin.createQuarter()

  describe "VendingMachine.insert_coin/2" do
    test "Adding valid coin to vending machine updates staging" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @quarter)
      assert vm.staging == [@quarter]
    end

    test "Adding invalid coin updates coin_return" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @invalid)
      assert vm.coin_return == [@invalid]
    end

    test "If staging is empty and you insert an invalid coin and vending machine cannot make change machine still displays 'EXACT CHANGE ONLY'" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @invalid)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "EXACT CHANGE ONLY"
    end

    test "If staging is empty and you insert a nickel vending machine displays $0.05" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @nickel)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.05"
    end

    test "If staging is empty and you insert a dime vending machine displays $0.10" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @dime)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.10"
    end

    test "If staging is empty and you insert a quarter vending machine displays $0.25" do
      vm = %VendingMachine{}
      vm = VendingMachine.insert_coin(vm, @quarter)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.25"
    end
  end

  describe "VendingMachine.select_product/2 grid functionality" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [@nickel, @nickel, @dime]
        }
      }
    end

    test "displays price of cola if selected before enough money has been inserted", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :cola)
      assert elem(VendingMachine.check_display(vm), 1) == "PRICE $1.00"
    end

    test "If cola is selected and not enough money has been inserted and display is checked twice then INSERT COIN is displayed",
         %{
           vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :cola)
      {vm, _} = VendingMachine.check_display(vm)
      assert elem(VendingMachine.check_display(vm), 1) == "INSERT COIN"
    end
  end

  describe "VendingMachine.select_product/2 display functionality of full Vending Machine" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [
            @nickel,
            @nickel,
            @dime
          ]
        }
      }
    end

    test "if cola selected and staging is not enough then price of cola is displayed", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :cola)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $1.00"
    end

    test "if chips selected and staging is not enough then price of chips is displayed", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :chips)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $0.50"
    end

    test "if candy selected and staging is not enough then price of candy is displayed", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :candy)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $0.65"
    end

    test "if cola is selected and staging has enough money then THANK YOU is displayed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"
    end

    test "if chips are selected and staging has enough money then THANK YOU is displayed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"
    end

    test "if candy is selected and staging has enough money then THANK YOU is displayed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :candy)

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"
    end

    test "if cola is dispensed and display is checked twice then INSERT COIN is displayed",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      {vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "INSERT COIN"
    end

    test "if chips are dispensed and display is checked twice then INSERT COIN is displayed",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      {vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "INSERT COIN"
    end

    test "if candy is dispensed and display is checked twice then EXACT CHANGE ONLY is displayed",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :candy)
      {vm, message} = VendingMachine.check_display(vm)

      assert message == "THANK YOU"

      {_vm, message} = VendingMachine.check_display(vm)

      assert message == "EXACT CHANGE ONLY"
    end

    test "if cola is dispensed and change is returned then bank will be have $1.00 more",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.bank == [
               @nickel,
               @nickel,
               @dime,
               @quarter,
               @quarter,
               @quarter,
               @quarter
             ]
    end

    test "if cola is dispensed and change is returned then staging will be empty",
         %{
           vending_machine: vm
         } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.staging == []
    end

    test "vending machine does not create money out of thin air", %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)

      vm = VendingMachine.select_product(vm, :candy)

      assert get_value_of_coins(vm.staging) + get_value_of_coins(vm.bank) +
               get_value_of_coins(vm.coin_return) == 90
    end
  end

  describe "VendingMachine.select_product/2 display functionality of non-full Vending Machine" do
    setup do
      %{
        vending_machine: %VendingMachine{}
      }
    end

    test "if cola selected and sold out then vending machine displays SOLD OUT", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :cola)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end

    test "if chips selected and sold out then vending machine displays SOLD OUT", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :chips)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end

    test "if candy selected and sold out then vending machine displays SOLD OUT", %{
      vending_machine: vm
    } do
      vm = VendingMachine.select_product(vm, :candy)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end
  end

  describe "VendingMachine.select_product/2 vending functionality of full Vending Machine" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ]
        }
      }
    end

    test "if cola selected and staging has enough money then product is dispensed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.bin == [%Product{name: :cola}]
    end

    test "if cola selected and not sold out and staging has enough money then cola inventory decreases by one",
         %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :cola)

      assert vm.inventory == [%Product{name: :chips}, %Product{name: :candy}]
    end

    test "if chips selected and staging has enough money then product is dispensed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      assert vm.bin == [%Product{name: :chips}]
    end

    test "if chips selected and not sold out and staging has enough money then chips inventory decreases by one",
         %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      assert vm.inventory == [%Product{name: :cola}, %Product{name: :candy}]
    end

    test "if candy selected and staging has enough money then product is dispensed", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@nickel)

      vm = VendingMachine.select_product(vm, :candy)

      assert vm.bin == [%Product{name: :candy}]
    end

    test "if candy selected and not sold out and staging has enough money then candy inventory decreases by one",
         %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@nickel)

      vm = VendingMachine.select_product(vm, :candy)

      assert vm.inventory == [%Product{name: :cola}, %Product{name: :chips}]
    end
  end

  describe "VendingMachine.select_product/2 returns correct change" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [
            @dime,
            @nickel,
            @nickel
          ]
        }
      }
    end

    test "If $0.75 is deposited and candy is selected then 10c is returned", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :candy)

      assert vm.coin_return == [@dime]
    end

    test "If $1.05 is deposited and cola is selected then 5c is returned", %{vending_machine: vm} do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)
        |> VendingMachine.insert_coin(@dime)

      vm = VendingMachine.select_product(vm, :cola)
      assert vm.coin_return == [@nickel]
    end

    test "If $0.75 is deposited and chips are selected then 25c is returned", %{
      vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)
      assert vm.coin_return == [@quarter]
    end
  end

  describe "VendingMachine.return_coins/1" do
    test "returns quarter if quarter is in staging" do
      vm = %VendingMachine{staging: [@quarter], coin_return: []}
      vm = VendingMachine.return_coins(vm)
      assert vm.staging == [] && vm.coin_return == [@quarter]
    end
  end

  describe "VendingMachine.check_display/1" do
    setup do
      %{
        sold_out_vending_machine: %VendingMachine{
          inventory: [],
          bank: [
            @nickel,
            @nickel,
            @dime
          ]
        },
        full_vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: [
            @nickel,
            @nickel,
            @dime
          ]
        },
        broke_vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ],
          bank: []
        },
        empty_vending_machine: %VendingMachine{
          inventory: [],
          bank: []
        }
      }
    end

    test "If not enough money has been inserted, because no money has been inserted and product is sold out, but product is selected and display is checked SOLD OUT is displayed",
         %{
           sold_out_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :cola)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "SOLD OUT"
    end

    test "If not enough money has been inserted, because some money has been inserted, but not enough and product is sold out, but product is selected and display is checked twice then amount in staging is displayed",
         %{
           sold_out_vending_machine: vm
         } do
      vm = VendingMachine.insert_coin(vm, @quarter)
      vm = VendingMachine.select_product(vm, :cola)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.25"
    end

    test "If not enough money has been inserted, because some, but not money has been inserted and product is sold out, but product is selected and display is checked twice then INSERT COIN is displayed",
         %{
           sold_out_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :cola)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "INSERT COIN"
    end

    test "If not enough money has been inserted and product is not sold out, but product is selected and display is checked price of product is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :cola)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "PRICE $1.00"
    end

    test "If not enough money has been inserted, because no money has been inserted and cola is not sold out, but cola is selected and display is checked twice then INSERT COIN is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :cola)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "INSERT COIN"
    end

    test "If not enough money has been inserted, some money has been inserted and cola is not sold out, but cola is selected and display is checked twice then amount of money already inserted is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.insert_coin(vm, @quarter)
      vm = VendingMachine.select_product(vm, :cola)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.25"
    end

    test "If not enough money has been inserted, because no money has been inserted and chips is not sold out, but chips is selected and display is checked twice then INSERT COIN is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :chips)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "INSERT COIN"
    end

    test "If not enough money has been inserted, some money has been inserted and chips is not sold out, but chips is selected and display is checked twice then amount of money already inserted is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.insert_coin(vm, @quarter)
      vm = VendingMachine.select_product(vm, :chips)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.25"
    end

    test "If not enough money has been inserted, because no money has been inserted and candy is not sold out, but candy is selected and display is checked twice then INSERT COIN is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :candy)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "INSERT COIN"
    end

    test "If not enough money has been inserted, some money has been inserted and candy is not sold out, but candy is selected and display is checked twice then amount of money already inserted is displayed",
         %{
           full_vending_machine: vm
         } do
      vm = VendingMachine.insert_coin(vm, @quarter)
      vm = VendingMachine.select_product(vm, :candy)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "$0.25"
    end

    test "If bank can make change and display is checked INSERT COIN should be displayed",
         %{
           full_vending_machine: vm
         } do
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "INSERT COIN"
    end

    test "If bank can not make change and display is checked EXACT CHANGE ONLY should be displayed",
         %{
           broke_vending_machine: vm
         } do
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "EXACT CHANGE ONLY"
    end

    test "If bank can not make change and cola is selected and 'PRICE $1.00' is displayed and display is checked again. Then display should say 'EXACT CHANGE ONLY'",
         %{
           broke_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :cola)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "EXACT CHANGE ONLY"
    end

    test "If bank can not make change and candy is selected and 'PRICE $0.65' is displayed and display is checked again. Then display should say 'EXACT CHANGE ONLY'",
         %{
           broke_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :candy)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "EXACT CHANGE ONLY"
    end

    test "If bank can not make change and chips are selected and 'PRICE $0.50' is displayed and display is checked again. Then display should say 'EXACT CHANGE ONLY'",
         %{
           broke_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :chips)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "EXACT CHANGE ONLY"
    end

    test "If bank cannot make change and cola is sold out and cola is selected an 'SOLD OUT' is displayed and display is checked again. Then display should say 'EXACT CHANGE ONLY'",
         %{
           empty_vending_machine: vm
         } do
      vm = VendingMachine.select_product(vm, :chips)
      {vm, _message} = VendingMachine.check_display(vm)
      {_vm, message} = VendingMachine.check_display(vm)
      assert message == "EXACT CHANGE ONLY"
    end
  end

  describe "VendingMachine.select_product/2" do
    setup do
      %{
        broke_vending_machine: %VendingMachine{
          inventory: [
            %Product{name: :cola},
            %Product{name: :chips},
            %Product{name: :candy}
          ]
        }
      }
    end

    test "returns all coins when enforcing correct change", %{
      broke_vending_machine: vm
    } do
      vm =
        VendingMachine.insert_coin(vm, @quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)
        |> VendingMachine.insert_coin(@quarter)

      vm = VendingMachine.select_product(vm, :chips)

      assert vm.staging == []
      assert vm.coin_return == [@quarter, @quarter, @quarter, @quarter]
    end
  end

  describe "VendingMachine.transfer/4" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [],
          bank: %CoinStorage{
            wallet: [@dime, @nickel, @nickel],
            tally: %{quarter: 0, dime: 1, nickel: 2},
            total: 20
          },
          coin_return: %CoinStorage{
            wallet: [],
            tally: %{quarter: 0, dime: 0, nickel: 0},
            total: 0
          },
          staging: %CoinStorage{
            wallet: [@quarter, @quarter, @quarter],
            tally: %{quarter: 3, dime: 0, nickel: 0},
            total: 75
          }
        }
      }
    end

    test "If vending machine transfers dime from bank to coin_return then bank will have 10c less and coin_return will have 10c more",
         %{vending_machine: vm} do
      vm = VendingMachine.transfer(vm, :bank, :coin_return, Coin.createDime())

      assert CoinStorage.equal?(vm.bank, %CoinStorage{
               wallet: [@nickel, @nickel],
               tally: %{quarter: 0, dime: 0, nickel: 2},
               total: 10
             }) == true

      assert CoinStorage.equal?(vm.coin_return, %CoinStorage{
               wallet: [@dime],
               tally: %{quarter: 0, dime: 1, nickel: 0},
               total: 10
             }) == true
    end
  end

  describe "VendingMachine.give_change/2" do
    setup do
      %{
        vending_machine: %VendingMachine{
          inventory: [],
          bank: %CoinStorage{
            wallet: [@dime, @nickel, @nickel],
            tally: %{quarter: 0, dime: 1, nickel: 2},
            total: 20
          },
          coin_return: %CoinStorage{
            wallet: [],
            tally: %{quarter: 0, dime: 0, nickel: 0},
            total: 0
          },
          staging: %CoinStorage{
            wallet: [@quarter, @quarter, @quarter],
            tally: %{quarter: 3, dime: 0, nickel: 0},
            total: 75
          }
        }
      }
    end

    test "If Vending Machine owes user 10c and staging does not have a dime then Vending Machine will transfer dime from bank to coin return",
         %{vending_machine: vm} do
      vm = VendingMachine.give_change(vm, 10)

      assert CoinStorage.equal?(vm.bank, %CoinStorage{
               wallet: [@nickel, @nickel],
               tally: %{quarter: 0, dime: 0, nickel: 2},
               total: 10
             }) == true

      assert CoinStorage.equal?(vm.coin_return, %CoinStorage{
               wallet: [@dime],
               tally: %{quarter: 0, dime: 1, nickel: 0},
               total: 10
             }) == true
    end
  end
end
