require 'minitest/autorun'
require 'subtitle'
require 'srt'
require 'scc'
require 'ttml'
require 'dfxp'
require 'vtt'

class SubtitleTest < Minitest::Test

  describe "Subtitle SRT Test" do
    subtitle = Subtitle.new("./samples/noextension/sample_srt")
    srt = SRT.new("./samples/srt/sample1.srt")
    it "Test Type for non extension File" do
      assert_equal "srt", subtitle.type
    end

    it "Test Validity of the SRT file" do
      valid = srt.is_valid?
      assert_equal true, valid
    end
  end

  describe "Subtitle VTT Test" do
    subtitle = Subtitle.new("./samples/noextension/sample_vtt")
    vtt = VTT.new("./samples/vtt/sample1.vtt")
    it "Test VTT for Non extenstion File" do
      assert_equal "vtt", subtitle.type
    end

    it "Test Validity of the VTT file" do
      valid = vtt.is_valid?
      assert_equal true, valid
    end
  end

  describe "Subtitle SCC Test" do
    subtitle = Subtitle.new("./samples/noextension/sample_scc")
    scc = SCC.new("./samples/scc/sample1.scc")
    it "Test SCC for Non extenstion File" do
      assert_equal "scc", subtitle.type
    end

    it "Test Validity of the SCC file" do
      valid = scc.is_valid?
      assert_equal true, valid
    end
  end

  describe "Subtitle TTML Test" do
    subtitle = Subtitle.new("./samples/noextension/sample_ttml")
    ttml = TTML.new("./samples/ttml/sample.ttml")
    it "Test TTML for Non extenstion File" do
      assert_equal "ttml", subtitle.type
    end

    it "Test Validity of the TTML file" do
      valid = ttml.is_valid?
      assert_equal true, valid
    end
  end

  describe "Subtitle DFXP Test" do
    subtitle = Subtitle.new("./samples/noextension/sample_dfxp")
    dfxp = DFXP.new("./samples/dfxp/sample.dfxp")
    it "Test DFXP for Non extenstion File" do
      assert_equal "dfxp", subtitle.type
    end

    it "Test Validity of the DFXP file" do
      valid = dfxp.is_valid?
      assert_equal true, valid
    end
  end
end