# This is a container for an entry in a list of PowerPoint packages
# containing slides that are to be inserted into a base PowerPoint deck.
class SlideSet

  # name is a string that is expected to match a string found in a
  # pptx file, marking the point at which to insert the slides
  # contained in "package".
  # package is an opened pptx file (not a file path)
  def initialize name, package
    @name = name
    @package = package
  end

  def name
    @name
  end

  def package
    @package
  end

end