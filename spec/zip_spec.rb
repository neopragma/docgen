require "spec_helper"

describe 'Zip and unzip functionality' do

  before(:each) do
    @docgen = DocgenTest.new
  end

  it 'reads the entries in a zip file' do
    expected_content = ["this is the entry \'dir1/dir11/file111\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir1/file11\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir1/file12\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir2/dir21/dir221/file2221\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'dir2/file21\' in my test archive!\n\nIt has only a few lines.\n", "this is the entry \'file1\' in my test archive!\n\nIt has only a few lines.\n"]
    expect(@docgen.unzip('spec/data/zipWithDirs.zip')).to eq(expected_content)
  end

  it 'saves extracted files in a directory' do
    expected_result = ["ziptemp/dir2", "ziptemp/dir2/file21", "ziptemp/dir2/dir21", "ziptemp/dir2/dir21/dir221", "ziptemp/dir2/dir21/dir221/file2221", "ziptemp/dir1", "ziptemp/dir1/file11", "ziptemp/dir1/dir11", "ziptemp/dir1/dir11/file111", "ziptemp/dir1/file12", "ziptemp/file1"]
    @docgen.unzip('spec/data/zipWithDirs.zip')
    expect(Dir[File.join('ziptemp', '**', '*')]).to eq(expected_result)
  end

  it 'creates a zip file with the contents of a directory' do
    expected_entry_names = ["dir1/", "dir1/dir2/", "dir1/dir2/file3", "dir1/file2", "file1"]
    source_dirname = 'spec/data/zipdir'
    target_filename = 'spec/data/test.zip'
    @docgen.zip(source_dirname, target_filename)
    expect(File.exist?(target_filename)).to be true
    expect(@docgen.zip_entries(target_filename)).to eq(expected_entry_names)
  end

end
