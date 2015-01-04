class Man
	attr_reader :name, :fiance, :proposed_women

	Prefs_m = {
	  'abe' => %W(abi eve cath ivy jan dee fay bea hope gay),
	  'bob' => %W(cath hope abi dee eve fay bea jan ivy gay),
	  'col' => %W(hope eve abi dee bea fay ivy gay cath jan),
	  'dan' => %W(ivy fay dee gay hope eve jan bea cath abi),
	   'ed' => %W(jan dee bea cath fay eve abi ivy hope gay),
	 'fred' => %W(bea abi dee gay eve ivy cath jan hope fay),
	  'gav' => %W(gay eve ivy bea cath abi dee hope jan fay),
	  'hal' => %W(abi eve hope fay ivy cath jan bea gay dee),
	  'ian' => %W(hope cath dee gay bea abi fay ivy jan eve),
	  'jon' => %W(abi fay jan gay eve bea dee cath ivy hope),
	}

	@@all = nil
	def self.all
		@@all ||= Prefs_m.keys.map{|m| Man.new(m) }
	end

	def self.find(m_name)
		all.detect{|m| m.name == m_name }
	end

	def self.free_men_with_unproposed_women
		all.select{|m| m.free? && m.unproposed_women? }
	end

	def initialize(name)
		@name = name
		@fiance = nil
		@proposed_women = []
	end

	def free?
		@fiance.nil?
	end

	def free!
		@fiance = nil
	end

	def free_fiance!
		fiance && Woman.find(fiance).free!
	end

	def engage!(w_name)
		@fiance = w_name
	end

	def prefs
		Prefs_m[@name]
	end

	def proposed!(w_name)
		@proposed_women << w_name
	end

	def unproposed_women
		prefs - proposed_women
	end

	def unproposed_women?
		unproposed_women.size > 1
	end

	def most_preferred_unproposed_woman
		unproposed_women.min_by do |w_name|
			prefs.index(w_name) || 100
		end
	end

	def pref_rank_for(w_name)
		prefs.index(w_name) || 100
	end

	def prefer_more?(w_name)
		fiance &&
		pref_rank_for(w_name) < pref_rank_for(fiance)
	end

	def try_matching
		m = self
		w = Woman.find(m.most_preferred_unproposed_woman)

		if w.free?
			Engagement.engage(m, w)
		else
			if w.prefer_more?(m.name)
				w.free_fiance!
				Engagement.engage(m, w)
			end
		end

		m.proposed!(w.name)		
	end

end

class Woman
	attr_reader :name, :fiance, :proposed_men

	Prefs_w = {
	  'abi' => %W(bob fred jon gav ian abe dan ed col hal),
	  'bea' => %W(bob abe col fred gav dan ian ed jon hal),
	 'cath' => %W(fred bob ed gav hal col ian abe dan jon),
	  'dee' => %W(fred jon col abe ian hal gav dan bob ed),
	  'eve' => %W(jon hal fred dan abe gav col ed ian bob),
	  'fay' => %W(bob abe ed ian jon dan fred gav col hal),
	  'gay' => %W(jon gav hal fred bob abe col ed dan ian),
	 'hope' => %W(gav jon bob abe ian dan hal ed col fred),
	  'ivy' => %W(ian col hal gav fred bob abe ed jon dan),
	  'jan' => %W(ed hal gav abe bob jon col ian fred dan),
	}

	@@all = nil
	def self.all
		@@all ||= Prefs_w.keys.map{|w| Woman.new(w) }
	end

	def self.find(w_name)
		all.detect{|w| w.name == w_name}
	end

	def self.free_women_with_unproposed_men
		all.select{|w| w.free? && w.unproposed_men? }
	end

	def initialize(name)
		@name = name
		@fiance = nil
		@proposed_men = []
	end

	def free?
		@fiance.nil?
	end

	def free!
		@fiance = nil
	end

	def engage!(m_name)
		@fiance = m_name
	end

	def free_fiance!
		fiance && Man.find(fiance).free!
	end

	def prefs
		Prefs_w[@name]
	end

	def proposed!(m_name)
		@proposed_men << m_name
	end

	def unproposed_men
		prefs - proposed_men
	end

	def unproposed_men?
		unproposed_men.size > 0
	end

	def most_preferred_unproposed_man
		unproposed_men.min_by do |m_name|
			pref_rank_for(m_name) || 100
		end
	end

	def pref_rank_for(m_name)
		prefs.index(m_name) || 100
	end

	def prefer_more?(m_name)
		pref_rank_for(m_name) < pref_rank_for(fiance)
	end

	def try_matching
		w = self
		m = Man.find(w.most_preferred_unproposed_man)

		if m.free?
			Engagement.engage(m ,w)
		else
			if m.prefer_more?(w.name)
				m.free_fiance!
				Engagement.engage(m, w)
			end
		end

		w.proposed!(m.name)
	end
end


class Engagement

	def self.engage(m, w)
		m.engage!(w.name)
		w.engage!(m.name)		
	end

	def self.list
		list = []
		Man.all.each do |m|
			next if m.free?
			list << [m.name, m.fiance]
		end
		list	
	end

	def self.printable_list
		list.map{|(m_name, w_name)| "#{m_name} - #{w_name}"}
	end

	def self.stable?
		men = list.map{|(m_name, w_name)| Man.find(m_name) }
		women = list.map{|(m_name, w_name)| Woman.find(w_name) }

		women.each do |w|
			other_men = men - [Man.find(w.fiance)]
			return false if other_men.any? do |m|
				w.prefer_more?(m.name) && m.prefer_more?(w.name)
			end
		end

		men.each do |m|
			other_women = women - [Woman.find(m.fiance)]
			return false if other_women.any? do |w|
				w.prefer_more?(m.name) && m.prefer_more?(w.name)
			end
		end

		true
	end

	def self.stability
		stable? ? 'stable' : 'unstable'
	end

	def self.run_m
		loop do
		  mens_list = Man.free_men_with_unproposed_women
		  break if mens_list.empty?
			
			m = mens_list.first
			m.try_matching
		end
	end

	def self.run_f
		loop do 
			women_list = Woman.free_women_with_unproposed_men
			break if women_list.empty?

			w = women_list.first
			w.try_matching
		end
	end

end

if $0 == __FILE__
	Engagement.run_m
	puts Engagement.printable_list
	puts Engagement.stability
end
