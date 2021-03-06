;nyquist plugin
;version 4
;type process
;name "Spectral edit multi tool"
;action "Filtering..."
;author "Paul Licameli"
;copyright "Released under terms of the GNU General Public License version 2"


;; SpectralEditMulti.ny by Paul Licameli, November 2014.
;; Updated to version 4 by Steve Daulton November 2014.
;; Released under terms of the GNU General Public License version 2:
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.html

(defun wet (sig)
  (let ((f0 (get '*selection* 'low-hz))
        (f1 (get '*selection* 'high-hz))
        (fc (get '*selection* 'center-hz)))
    (cond
      ((not (or f0 f1)) (throw 'error-message "Please select frequencies."))
      ((not f0) (highpass2 sig f1))
      ((not f1) (lowpass2 sig f0))
      ((= f0 f1) (throw 'error-message "Bandwidth is zero.\nSelect a frequency range."))
      (T (let ((q (/ fc (- f1 f0))))
           (notch2 sig fc q))))))

(defun result (sig)
  (let* ((tn (truncate len))
        (rate (snd-srate sig))
        (transition (truncate (* 0.01 rate))) ; 10 ms
        (t1 (min transition (/ tn 2)))        ; fade in length (samples)
        (t2 (max (- tn transition) (/ tn 2))) ; length before fade out (samples)
        (breakpoints (list t1 1.0 t2 1.0 tn))
        (env (snd-pwl 0.0 rate breakpoints)))
    (sum (prod env (wet sig)) (prod (diff 1.0 env) sig))))

(if (string-not-equal (get '*TRACK* 'VIEW) "spectrogram"  :end1 4 :end2 4)
    "Use this effect in the 'Spectrogram'\nor 'Spectrogram (log f)' view."
    (catch 'error-message
      (multichan-expand #'result *track*)))
