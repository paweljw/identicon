defmodule Identicon do
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Builds Identicon.Image with a hash from given string.

  ## Examples

    iex> Identicon.hash_input("pjw")
    %Identicon.Image{hex: [48, 238, 109, 168, 21, 246, 115, 213, 231, 212, 98, 100, 49, 45, 131, 240]}
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  @doc """
    Augments a given Identicon.Image with color plucked from contained hex.

  ## Examples

    iex> Identicon.hash_input("pjw") |> Identicon.pick_color
    %Identicon.Image{color: {48, 238, 109},
                     hex: [48, 238, 109, 168, 21, 246, 115, 213, 231, 212, 98, 100, 49, 45, 131, 240]}
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
    Augments a give Identicon.Image with grid built off of contained hex.

  ## Examples
    
    iex> Identicon.hash_input("pjw") |> Identicon.build_grid
    %Identicon.Image{color: nil,
                     grid: [{48, 0}, {238, 1}, {109, 2}, {238, 3}, {48, 4}, {168, 5},
                           {21, 6}, {246, 7}, {21, 8}, {168, 9}, {115, 10}, {213, 11},
                           {231, 12}, {213, 13}, {115, 14}, {212, 15}, {98, 16}, {100, 17},
                           {98, 18}, {212, 19}, {49, 20}, {45, 21}, {131, 22}, {45, 23},
                           {49, 24}],
                     hex: [48, 238, 109, 168, 21, 246, 115, 213, 231, 212, 98, 100, 49,
                           45, 131, 240]}
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid = hex
    |> Enum.chunk(3)
    |> Enum.map(&mirror_row/1)
    |> List.flatten
    |> Enum.with_index
    %Identicon.Image{image | grid: grid}
  end

  @doc """
    Mirrors first two elements of a row onto the end.

  ## Examples

    iex> Identicon.mirror_row([1, 2, 3])
    [1, 2, 3, 2, 1]
  """
  def mirror_row([first, second | _] = row) do
    row ++ [second, first]
  end

  @doc """
    Drops odd codes from grid.

  ## Examples
    
    iex> Identicon.hash_input("pjw") |> Identicon.build_grid |> Identicon.filter_odd_squares
    %Identicon.Image{color: nil,
                     grid: [{48, 0}, {238, 1}, {238, 3}, {48, 4}, {168, 5},
                            {246, 7}, {168, 9}, {212, 15}, {98, 16}, {100, 17},
                            {98, 18}, {212, 19}],
                     hex: [48, 238, 109, 168, 21, 246, 115, 213, 231, 212, 98, 100, 49,
                           45, 131, 240]}
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = grid |> Enum.filter(fn ({code, _}) -> rem(code, 2) == 0 end)
    %Identicon.Image{image | grid: grid}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn ({_, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50
      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}
      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn ({top_left, bottom_right}) ->
      :egd.filledRectangle(image, top_left, bottom_right, fill)
    end

    :egd.render(image)
  end

  def save_image(image, filename) do
    File.write("images/#{filename}.png", image)
  end
end
