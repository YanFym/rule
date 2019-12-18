defmodule Rules do
  @operations %{less_than: :<, more_than: :>, equal: :==,
    	       more_or_equla_than: :>=, less_or_equal_than: :<=}

  def calculate(rules, settings) do
    case is_valid?(rules,settings) do
      {:ok} ->
        rules
        |> Enum.filter(&(fetch_field(&1.rule) == Map.keys(settings)))
        |> Enum.map(&(%{output_value: &1.output_value, rule: new_field(&1.rule,settings)}))
        |> Enum.map(&(%{output_value: &1.output_value, rule: is_operation_right?(&1.rule)}))
        |> Enum.map(&(%{output_value: &1.output_value, rule: Enum.uniq(&1.rule)}))
        |> Enum.find(&(&1.rule == [true]))
        |> fetch_result
        

      {:error} -> {:error, :bad_data}
      _ -> {:unknown_error}
    end
  end

  defp is_valid?(list,hash) do 
    unless is_list(list) && is_map(hash) do
      {:error}
    else
      {:ok}
    end
  end
  
  defp fetch_field(rule) do
    rule 
    |> Enum.map(&(&1.field))
    |> Enum.map(&(String.to_atom(&1)))
  end

  defp new_field(rule,settings) do 
    rule
    |> Enum.map(&(%{&1 | field: settings[String.to_atom(&1.field)]}))
  end 

  defp is_operation_right?(rule) do
    rule
    |> Enum.map(&(
    	if is_operation_in_list?(&1.operation) do 
    	  apply(Kernel, @operations[String.to_atom(&1.operation)], [&1.field, &1.compared_value])
    	else
    	  set_function(&1)
    	end)) 
  end

  defp set_function(rule) do
    if rule.operation == "in_set" do
      Enum.any?(rule.compared_value,&(&1 == rule.field))
    else 
      if rule.operation == "not_in_set" do
        !Enum.any?(rule.compared_value,&(&1 == rule.field))
      else
        {:error, :no_correct_opiration}
      end
    end
  end

  defp is_operation_in_list?(operation) do
    Map.keys(@operations)
    |> Enum.any?(&(&1 ==  String.to_atom(operation)))
  end

  def fetch_result(rules) do
    if rules != nil do
      {:ok, rules.output_value}
    else
      {:error, :no_maches}
    end
  end
end       
